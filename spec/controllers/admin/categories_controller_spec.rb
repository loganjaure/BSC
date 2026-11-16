
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::CategoriesController, type: :controller do
  let!(:semester) do
    Semester.create!(term_name: 'Fall 2026')
  end

  let!(:category) do
    Category.create!(category_name: 'Marketing')
  end

  let!(:replacement_category) do
    Category.create!(category_name: 'General Business')
  end

  let!(:signed_in_user) do
    User.create!(email: 'admin-test@tamu.edu')
    end

    let!(:signed_in_member) do
    Member.create!(
        user: signed_in_user,
        name: 'Admin Test',
        tamu_email: 'admin-test@tamu.edu',
        uin: '987654321',
        class_year: 2027
    )
    end

    before do
    session[:user_id] = signed_in_user.id
    allow(controller).to receive(:require_admin)
    end

  def create_event(category)
    Event.create!(
      category: category,
      semester: semester,
      event_name: 'Test Event',
      description: 'Test event description',
      event_date_time: 1.day.ago,
      point_value: 2
    )
  end

  describe 'DELETE #destroy' do
    context 'when the category has semester requirements but no events' do
      before do
        SemesterRequirement.create!(
          semester: semester,
          category: category,
          required_count: 3
        )
      end

      it 'deletes the category and its semester requirements' do
        expect {
          delete :destroy, params: { id: category.id }
        }.to change(Category, :count).by(-1)
          .and change(SemesterRequirement, :count).by(-1)

        expect(response).to redirect_to(admin_events_path(anchor: 'categories'))
        expect(flash[:notice]).to be_present
      end
    end

    context 'when the category has associated events' do
      let!(:event) { create_event(category) }

      it 'reassigns events to the replacement category instead of deleting them' do
        category_count = Category.count
        event_count = Event.count

        delete :destroy, params: {
            id: category.id,
            replacement_category_id: replacement_category.id
        }

        expect(Category.count).to eq(category_count - 1)
        expect(Event.count).to eq(event_count)
        expect(event.reload.category).to eq(replacement_category)
        expect(response).to redirect_to(admin_events_path(anchor: 'categories'))
      end

      it 'preserves attendance records when reassigning events' do
        user = User.create!(email: 'member@tamu.edu')
        member = Member.create!(
          user: user,
          name: 'Test Member',
          tamu_email: 'member@tamu.edu',
          uin: '123456789',
          class_year: 2027
        )

        attendance = Attendance.create!(
          member: member,
          event: event,
          check_in_time: Time.current,
          status: 'present'
        )

        delete :destroy, params: {
          id: category.id,
          replacement_category_id: replacement_category.id
        }

        expect(event.reload.category).to eq(replacement_category)
        expect(attendance.reload.event).to eq(event)
      end

      it 'does not delete the category when no replacement is selected' do
        expect {
          delete :destroy, params: { id: category.id }
        }.not_to change(Category, :count)

        expect(category.reload).to be_present
        expect(event.reload.category).to eq(category)
        expect(response).to redirect_to(admin_categories_path)
        expect(flash[:alert]).to be_present
      end

      it 'does not allow the category to replace itself' do
        expect {
          delete :destroy, params: {
            id: category.id,
            replacement_category_id: category.id
          }
        }.not_to change(Category, :count)

        expect(category.reload).to be_present
        expect(event.reload.category).to eq(category)
      end
    end

    context 'when the category has no events or semester requirements' do
      it 'deletes the category without requiring a replacement' do
        expect {
          delete :destroy, params: { id: category.id }
        }.to change(Category, :count).by(-1)

        expect(response).to redirect_to(admin_events_path(anchor: 'categories'))
      end
    end

    context 'when an event cannot be reassigned' do
      let!(:event) { create_event(category) }

      it 'rolls back the deletion' do
        allow_any_instance_of(Event).to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(event))

        expect {
          delete :destroy, params: {
            id: category.id,
            replacement_category_id: replacement_category.id
          }
        }.not_to change(Category, :count)

        expect(category.reload).to be_present
        expect(event.reload.category).to eq(category)
        expect(response).to redirect_to(admin_categories_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
