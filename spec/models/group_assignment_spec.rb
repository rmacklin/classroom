# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GroupAssignment, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'slug uniqueness' do
    let(:organization) { create(:organization) }

    it 'verifes that the slug is unique even if the titles are unique' do
      create(:group_assignment, organization: organization, title: 'group-assignment-1')
      new_group_assignment = build(:group_assignment, organization: organization, title: 'group assignment 1')

      expect { new_group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'uniqueness of title across organization' do
    let(:organization) { create(:organization)    }
    let(:creator)      { organization.users.first }

    let(:grouping) { Grouping.create(title: 'Grouping', organization: organization) }

    let(:assignment) { create(:assignment, organization: organization) }
    let(:group_assignment) { create(:group_assignment, organization: organization) }

    it 'validates that an Assignment in the same organization does not have the same title' do
      group_assignment.title = assignment.title

      validation_message = 'Validation failed: Your assignment title must be unique'
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe 'uniqueness of title across application' do
    let(:organization_1) { create(:organization) }
    let(:organization_2) { create(:organization) }

    it 'allows two organizations to have the same GroupAssignment title and slug' do
      group_assignment_1 = create(:assignment, organization: organization_1)
      group_assignment_2 = create(:group_assignment, organization: organization_2, title: group_assignment_1.title)

      expect(group_assignment_2.title).to eql(group_assignment_1.title)
      expect(group_assignment_2.slug).to eql(group_assignment_1.slug)
    end
  end

  context 'with group_assignment' do
    subject { create(:group_assignment) }

    describe 'when the title is updated' do
      it 'updates the slug' do
        subject.update_attributes(title: 'New Title')
        expect(subject.slug).to eql('new-title')
      end
    end

    describe 'when it has associated tasks' do
      it 'destroys them when it is destroyed' do
        tasks = [
          Task.create!(title: 'Task 1', assignment: subject),
          Task.create!(title: 'Task 2', assignment: subject)
        ]
        expect(subject.tasks.to_a).to eql(tasks)
        expect { subject.destroy }.to change { Task.count }.by(-2)
      end
    end

    describe '#flipper_id' do
      it 'should return an id' do
        expect(subject.flipper_id).to eq("GroupAssignment:#{subject.id}")
      end
    end

    describe '#public?' do
      it 'returns true if Assignments public_repo column is true' do
        expect(subject.public?).to be(true)
      end
    end

    describe '#private?' do
      it 'returns false if Assignments public_repo column is true' do
        expect(subject.private?).to be(false)
      end
    end
  end
end
