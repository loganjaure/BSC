# frozen_string_literal: true

module Admin
  class MemberManagement
    class Error < StandardError; end

    EDITABLE_FIELDS = %i[name uin class_year].freeze

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

    def destroy!
      with_authorized_member do
        blocker = deletion_blocker
        raise Error, blocker if blocker

        destroy_account!
      end
    rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey
      raise Error, 'Cannot delete this member because linked records or a deletion safeguard prevented it. Nothing was deleted.'
    end

    def deletion_blocker
      return 'Cannot delete the last administrator.' if last_admin?
      return 'You cannot delete your own account from the admin screen.' if own_account?
      return 'Cannot delete a member with attendance history. Keep the record to preserve their points and history.' if @member.attendances.exists?
      return 'Cannot delete a member who submitted or reviewed appeals. Keep the record to preserve appeal history.' if appeal_history?

      nil
    end

    private

    def with_authorized_member
      Member.transaction do
        # Lock both accounts in a consistent order, then recheck the actor's role.
        # This also serializes an admin trying to revoke/delete the acting admin.
        locked_members = Member.where(id: [ @actor&.id, @member.id ]).order(:id).lock.to_a
        actor = locked_members.find { |record| record.id == @actor&.id }
        raise Error, 'Access denied.' unless actor&.is_admin?

        @member.reload
        yield
      end
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
      @member.is_admin? && Member.where(is_admin: true).count <= 1
    end

    def own_account?
      @member.id == @actor&.id
    end

    def appeal_history?
      @member.submitted_appeals.exists? || @member.reviewed_appeals.exists?
    end

    def destroy_account!
      user = @member.user

      if user
        user.lock!
        shared_account = Member.where(user_id: user.id).where.not(id: @member.id).exists?
        raise Error, 'Cannot delete an account linked to more than one member. Resolve the duplicate link first.' if shared_account
      end

      @member.destroy!

      # Clear the has_one cache after deleting the member to avoid running
      user&.reload&.destroy!
    end
  end
end
