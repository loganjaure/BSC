require 'rails_helper'

RSpec.describe 'Admin features', type: :request do
  let!(:user) do
    User.create!(name: 'Test Admin', email: 'admin@tamu.edu')
  end

  let!(:member) do
    Member.create!(
      user: user,
      name: 'Test Admin',
      tamu_email: 'admin@tamu.edu',
      uin: 123004567,
      class_year: 2025,
      is_admin: true
    )
  end

  let!(:category) do
    Category.create!(category_name: 'Service')
  end

  let!(:semester) do
    Semester.create!(term_name: 'Fall 2025')
  end

  let!(:event) do
    Event.create!(
      event_name: 'Volunteer Day',
      event_date_time: Time.zone.parse('2025-10-10 10:00'),
      category: category,
      semester: semester,
      point_value: 2,
      description: 'Community volunteering'
    )
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(user)

    allow_any_instance_of(ApplicationController)
      .to receive(:current_member).and_return(member)
  end

  describe 'GET /admin/categories' do
    it 'returns success for an admin' do
      get admin_categories_path

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/events' do
    it 'returns success for an admin' do
      get admin_events_path

      expect(response).to have_http_status(:success)
    end
  end

  describe 'category creation' do
    it 'creates a category with valid parameters' do
      expect do
        post admin_categories_path,
             params: { category: { category_name: 'Community Service' } }
      end.to change(Category, :count).by(1)

      expect(response).to redirect_to(admin_events_path)
    end

    it 'rejects a category with a blank name' do
      expect do
        post admin_categories_path,
             params: { category: { category_name: '' } }
      end.not_to change(Category, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'category updating' do
    it 'updates a category with a valid name' do
      patch admin_category_path(category),
            params: { category: { category_name: 'Leadership' } }

      expect(response).to redirect_to(admin_events_path)
      expect(category.reload.category_name).to eq('Leadership')
    end

    it 'rejects a blank category name' do
      patch admin_category_path(category),
            params: { category: { category_name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(category.reload.category_name).to eq('Service')
    end
  end

  describe 'category deletion' do
    it 'deletes a category that is not in use' do
      unused_category = Category.create!(category_name: 'Unused')

      expect do
        delete admin_category_path(unused_category)
      end.to change(Category, :count).by(-1)

      expect(response).to redirect_to(admin_events_path)
    end

    it 'blocks deletion when the category has events' do
      expect do
        delete admin_category_path(category)
      end.not_to change(Category, :count)

      expect(response).to redirect_to(admin_categories_path)
      expect(flash[:alert]).to include('Cannot delete')
    end

    it 'blocks deletion when a semester requirement uses the category' do
      unused_category = Category.create!(category_name: 'Fundraising')

      SemesterRequirement.create!(
        semester: semester,
        category: unused_category,
        required_count: 2
      )

      expect do
        delete admin_category_path(unused_category)
      end.not_to change(Category, :count)

      expect(response).to redirect_to(admin_categories_path)
      expect(flash[:alert]).to include('Cannot delete')
    end
  end

  describe 'semester creation' do
    it 'creates a semester and returns to semester requirements' do
      expect do
        post admin_semesters_path, params: { semester: { term_name: 'Spring 2026' } }
      end.to change(Semester, :count).by(1)

      expect(response).to redirect_to(admin_semester_requirements_path)
      expect(flash[:notice]).to eq('Semester created successfully.')
    end

    it 'does not create a semester with a blank name' do
      expect do
        post admin_semesters_path, params: { semester: { term_name: ' ' } }
      end.not_to change(Semester, :count)

      expect(response).to redirect_to(admin_semester_requirements_path)
      expect(flash[:alert]).to include("can't be blank")
    end

    it 'does not create a semester with a duplicate name' do
      expect do
        post admin_semesters_path, params: { semester: { term_name: semester.term_name } }
      end.not_to change(Semester, :count)

      expect(response).to redirect_to(admin_semester_requirements_path)
      expect(flash[:alert]).to include('has already been taken')
    end
  end

  describe 'event creation' do
    let(:valid_event_params) do
      {
        event_name: 'Another Volunteer Day',
        event_date_time: Time.zone.parse('2025-11-10 10:00'),
        category_id: category.id,
        semester_id: semester.id,
        point_value: 2,
        description: 'Community volunteering'
      }
    end

    it 'creates an event with valid parameters' do
      expect do
        post admin_events_path, params: { event: valid_event_params }
      end.to change(Event, :count).by(1)

      expect(response).to redirect_to(admin_events_path)
    end

    it 'rejects an event with a blank name' do
      expect do
        post admin_events_path,
             params: {
               event: valid_event_params.merge(event_name: '')
             }
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'event updating' do
    it 'updates an event with valid parameters' do
      patch admin_event_path(event),
            params: { event: { event_name: 'Updated Volunteer Day' } }

      expect(response).to redirect_to(admin_events_path)
      expect(event.reload.event_name).to eq('Updated Volunteer Day')
    end

    it 'rejects an event with a blank name' do
      patch admin_event_path(event),
            params: { event: { event_name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(event.reload.event_name).to eq('Volunteer Day')
    end
  end

  describe 'authorization' do
    it 'redirects a non-admin away from the categories page' do
      member.update!(is_admin: false)

      get admin_categories_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied.')
    end

    it 'redirects a non-admin away from the events page' do
      member.update!(is_admin: false)

      get admin_events_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied.')
    end

    it 'redirects a signed-out visitor to the sign-in page' do
      allow_any_instance_of(ApplicationController)
        .to receive(:current_user).and_return(nil)

      allow_any_instance_of(ApplicationController)
        .to receive(:current_member).and_return(nil)

      get admin_categories_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('Please sign in')
    end
  end
end
