# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TasksController, type: :controller do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:user)         { organization.users.first                 }

  let(:assignment) { Assignment.create(title: 'Assignment', creator: user, organization: organization) }
  let(:group_assignment) do
    GroupAssignment.create(
      attributes_for(:group_assignment).merge(title: 'GroupAssignment', creator: user, organization: organization)
    )
  end

  let(:assignment_task) { Task.create(title: 'AssignmentTask', body: 'body', assignment: assignment) }
  let(:group_assignment_task) { Task.create(title: 'GroupAssignmentTask', body: 'body', assignment: group_assignment) }

  before do
    sign_in(user)
  end

  describe 'GET #new', :vcr do
    context 'for an Assignment' do
      it 'returns success and sets a new Task' do
        get :new, assignment_id: assignment.slug, organization_id: organization.slug
        expect(response).to have_http_status(:success)
        task = assigns(:task)
        expect(task).to be_a Task
        expect(task).to be_new_record
      end
    end

    context 'for a GroupAssignment' do
      it 'returns success and sets a new Task' do
        get :new, group_assignment_id: group_assignment.slug, organization_id: organization.slug
        expect(response).to have_http_status(:success)
        task = assigns(:task)
        expect(task).to be_a Task
        expect(task).to be_new_record
      end
    end
  end

  describe 'POST #create', :vcr do
    context 'for an Assignment' do
      it 'creates a new Task' do
        expect do
          post :create,
               assignment_id: assignment.slug,
               organization_id: organization.slug,
               task: { title: 'A Task', body: 'some body' }
        end.to change { Task.count }.by(1)
        expect(response).to redirect_to([:edit, organization, assignment, Task.last])
      end

      it 'does not create an invalid Task' do
        expect do
          post :create,
               assignment_id: assignment.slug,
               organization_id: organization.slug,
               task: { title: '', body: 'body' }
        end.to_not change { Task.count }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'for a GroupAssignment' do
      it 'creates a new Task' do
        expect do
          post :create,
               group_assignment_id: group_assignment.slug,
               organization_id: organization.slug,
               task: { title: 'A Task', body: 'some body' }
        end.to change { Task.count }.by(1)
        expect(response).to redirect_to([:edit, organization, group_assignment, Task.last])
      end

      it 'does not create an invalid Task' do
        expect do
          post :create,
               group_assignment_id: group_assignment.slug,
               organization_id: organization.slug,
               task: { title: '', body: 'body' }
        end.to_not change { Task.count }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #edit', :vcr do
    context 'for an Assignment' do
      it 'returns success and sets the task' do
        get :edit,
            id: assignment_task.position,
            assignment_id: assignment.slug,
            organization_id: organization.slug
        expect(response).to have_http_status(:success)
        expect(assigns(:task)).to eql(assignment_task)
      end
    end

    context 'for a GroupAssignment' do
      it 'returns success and sets the task' do
        get :edit,
            id: group_assignment_task.position,
            group_assignment_id: group_assignment.slug,
            organization_id: organization.slug
        expect(response).to have_http_status(:success)
        expect(assigns(:task)).to eql(group_assignment_task)
      end
    end
  end

  describe 'PATCH #update', :vcr do
    context 'for an Assignment' do
      it 'correctly updates the task' do
        task_attributes = { body: 'updated body' }
        patch :update,
              id: assignment_task.position,
              assignment_id: assignment.slug,
              organization_id: organization.slug,
              task: task_attributes

        expect(response).to redirect_to([:edit, organization, assignment, assignment_task])
        expect(assignment_task.reload.body).to eql(task_attributes[:body])
      end

      it 'does not update with invalid params' do
        patch :update,
              id: assignment_task.position,
              assignment_id: assignment.slug,
              organization_id: organization.slug,
              task: { title: '', body: 'body' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'for a GroupAssignment' do
      it 'correctly updates the task' do
        task_attributes = { body: 'updated body' }
        patch :update,
              id: group_assignment_task.position,
              group_assignment_id: group_assignment.slug,
              organization_id: organization.slug,
              task: task_attributes

        expect(response).to redirect_to([:edit, organization, group_assignment, group_assignment_task])
        expect(group_assignment_task.reload.body).to eql(task_attributes[:body])
      end

      it 'does not update with invalid params' do
        patch :update,
              id: group_assignment_task.position,
              group_assignment_id: group_assignment.slug,
              organization_id: organization.slug,
              task: { title: '', body: 'body' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy', :vcr do
    context 'for an Assignment' do
      it 'deletes the Task and redirects back to the assignment' do
        task = assignment_task
        expect do
          delete :destroy,
                 id: task.position,
                 assignment_id: assignment.slug,
                 organization_id: organization.slug
        end.to change { Task.count }.by(-1)

        expect(response).to redirect_to([:edit, organization, assignment])
      end
    end

    context 'for a GroupAssignment' do
      it 'deletes the Task and redirects back to the group assignment' do
        task = group_assignment_task
        expect do
          delete :destroy,
                 id: task.position,
                 group_assignment_id: group_assignment.slug,
                 organization_id: organization.slug
        end.to change { Task.count }.by(-1)

        expect(response).to redirect_to([:edit, organization, group_assignment])
      end
    end
  end
end
