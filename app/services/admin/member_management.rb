# frozen_string_literal: true

module Admin
  class MemberManagement
    class Error < StandardError; end

    EDITABLE_FIELDS = %i[name uin class_year tamu_email total_points].freeze

    def initialize(actor:, member:)
      @actor = actor
      @member = member
    end

    def update(attributes)
      with_authorized_member do
        @member.update(attributes.to_h.symbolize_keys.slice(*EDITABLE_FIELDS))
      end
    end

    def promote!
      with_authorized_member { change_role!(true) }
    end

    def revoke!
      with_authorized_member do
        raise Error, 'Cannot revoke the last administrator.' if last_admin?
        raise Error, 'You cannot revoke your own administrator status.' if own_account?

        change_role!(false)
      end
    end

    def archive!
      with_authorized_member do
        blocker = deletion_blocker
        raise Error, blocker if blocker

        raise Error, 'Cannot archive an account linked to more than one member. Resolve the duplicate link first.' if shared_account?

        @member.assign_attributes(archived_at: Time.current, archived_by_id: @actor.id, is_admin: false)
        @member.save(context: :admin_archive) || raise(Error, @member.errors.full_messages.to_sentence)
      end
    end

    def deletion_blocker
      return 'Cannot archive the last administrator.' if last_admin?
      return 'You cannot archive your own account from the admin screen.' if own_account?

      nil
    end

    private

    def with_authorized_member
      Member.transaction do
        # Lock both accounts in a consistent order, then recheck the actor's role.
        # This also serializes an admin trying to revoke/delete the acting admin.
        actor_id = @actor&.id
        locked_members = Member.where(id: [ actor_id, @member.id ]).order(:id).lock.to_a
        actor = locked_members.find { |record| record.id == actor_id }
        raise Error, 'Access denied.' unless active_admin?(actor)

        @member.reload
        raise Error, 'This member has been archived.' if @member.archived?

        yield
      end
    end

    def active_admin?(actor)
      actor&.is_admin? && !actor.archived?
    end

    def change_role!(enabled)
      return false if @member.is_admin? == enabled

      @member.is_admin = enabled

      # Role changes must work for seeded/incomplete profiles. This custom
      # context keeps unconditional validations and callbacks, but not the
      # UIN/class-year validations explicitly scoped to profile updates.
      @member.save(context: :admin_role_change) ||
        raise(Error, @member.errors.full_messages.to_sentence)
    end

    def last_admin?
      @member.is_admin? && Member.active.where(is_admin: true).count <= 1
    end

    def own_account?
      @member.id == @actor&.id
    end

    def shared_account?
      @member.user_id.present? && Member.where(user_id: @member.user_id).where.not(id: @member.id).exists?
    end
  end
end
