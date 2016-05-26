# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Task, type: :model do
  context 'with created objects' do
    let(:assignment_1) { create(:assignment, id: 1) }
    let(:assignment_2) { create(:assignment, id: 2) }
    let(:group_assignment) { create(:group_assignment, id: 1) }

    describe 'acts_as_list order' do
      it 'is scoped by [assignment_id, assignment_type]' do
        task_1 = Task.create!(title: 'A1 Task 1', assignment: assignment_1)
        task_2 = Task.create!(title: 'A1 Task 2', assignment: assignment_1)
        task_3 = Task.create!(title: 'A2 Task 1', assignment: assignment_2)
        task_4 = Task.create!(title: 'A2 Task 2', assignment: assignment_2)
        task_5 = Task.create!(title: 'GA Task 1', assignment: group_assignment)
        task_6 = Task.create!(title: 'GA Task 2', assignment: group_assignment)

        expect(assignment_1.tasks.to_a).to eql([task_1, task_2])
        expect(assignment_2.tasks.to_a).to eql([task_3, task_4])
        expect(group_assignment.tasks.to_a).to eql([task_5, task_6])
      end
    end
  end
end
