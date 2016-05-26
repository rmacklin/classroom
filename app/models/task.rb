# frozen_string_literal: true
class Task < ActiveRecord::Base
  belongs_to :assignment, polymorphic: true
  acts_as_list scope: [:assignment_id, :assignment_type]

  validates :title, presence: true

  def to_param
    position.to_s
  end
end
