# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe 'Associations' do
    it { should belong_to(:category) }
    it { should belong_to(:semester) }
    it { should have_many(:attendances) }
    it { should have_many(:members).through(:attendances) }
    it { should have_many(:appeals) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:event_name) }
    it { should validate_presence_of(:event_date_time) }
    it { should validate_numericality_of(:point_value).is_greater_than_or_equal_to(0) }
  end

  describe "#active?" do
    around do |example|
      travel_to(Time.zone.parse("2026-10-30 12:00:00")) do
        example.run
      end
    end

    it "allows check-in 15 minutes before the event" do
      event = Event.new(event_date_time: 15.minutes.from_now)

      expect(event.active?).to be true
    end

    it "does not allow check-in more than 15 minutes before the event" do
      event = Event.new(event_date_time: 16.minutes.from_now)

      expect(event.active?).to be false
    end

    it "allows check-in when the event starts" do
      event = Event.new(event_date_time: Time.current)

      expect(event.active?).to be true
    end

    it "allows check-in within 3 hours after the event starts" do
      event = Event.new(event_date_time: 2.hours.ago)

      expect(event.active?).to be true
    end

    it "allows check-in exactly 3 hours after the event starts" do
      event = Event.new(event_date_time: 3.hours.ago)

      expect(event.active?).to be true
    end

    it "does not allow check-in more than 3 hours after the event starts" do
      event = Event.new(event_date_time: 3.hours.ago - 1.second)

      expect(event.active?).to be false
    end

    it "does not allow check-in when the event date is missing" do
      event = Event.new(event_date_time: nil)

      expect(event.active?).to be false
    end
  end

  describe "#valid_check_in_code?" do
    context "when no check-in code is configured" do
      let(:event) { Event.new(check_in_code: nil) }

      it "accepts a blank submitted code" do
        expect(event.valid_check_in_code?(nil)).to be true
      end

      it "accepts a submitted code" do
        expect(event.valid_check_in_code?("1234")).to be true
      end
    end

    context "when a check-in code is configured" do
      let(:event) { Event.new(check_in_code: "1234") }

      it "accepts the correct code" do
        expect(event.valid_check_in_code?("1234")).to be true
      end

      it "rejects an incorrect code" do
        expect(event.valid_check_in_code?("5678")).to be false
      end

      it "rejects a blank submitted code" do
        expect(event.valid_check_in_code?("")).to be false
      end

      it "rejects a nil submitted code" do
        expect(event.valid_check_in_code?(nil)).to be false
      end
    end
  end
end
