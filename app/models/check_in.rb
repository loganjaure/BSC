class CheckIn < ApplicationRecord
    validates :member_id, :event_id, presence: true
end
