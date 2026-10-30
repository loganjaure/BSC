# frozen_string_literal: true

module Admin
  class AppealReview
    class Error < StandardError; end

    def initialize(actor:, appeal:)
      @actor = actor
      @appeal = appeal
    end

    def decide!(decision)
      raise Error, 'Select Approve or Deny.' unless %w[approved denied].include?(decision)

      Appeal.transaction do
        actor = lock_and_authorize_reviewer!

        @appeal.lock!
        raise Error, 'This appeal has already been reviewed.' unless @appeal.pending?

        record_attendance! if decision == 'approved'
        @appeal.update!(status: decision, reviewed_by_member: actor)
      end
    end

    private

    def lock_and_authorize_reviewer!
      actor_id = @actor&.id

      # Keep the same member lock order as MemberManagement.
      members = Member.where(id: [ actor_id, @appeal.submitting_member_id ])
                      .order(:id).lock.to_a
      actor = members.find { |member| member.id == actor_id }

      raise Error, 'Access denied.' unless actor&.is_admin? && !actor.archived?

      actor
    end

    def record_attendance!
      member = @appeal.submitting_member.reload
      raise Error, 'Cannot approve an appeal for an archived member.' if member.archived?

      # Preserve existing check-in times and administrator point adjustments.
      attendance = member.attendances.find_or_initialize_by(event_id: @appeal.event_id)
      attendance.update!(status: 'present')
    end
  end
end
