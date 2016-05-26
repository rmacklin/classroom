# frozen_string_literal: true
class TasksController < ApplicationController
  include OrganizationAuthorization

  before_action :set_assignment
  before_action :set_task, only: [:edit, :update, :destroy]

  decorates_assigned :organization

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params.merge(assignment: @assignment))

    if @task.save
      flash[:success] = "\"#{@task.title}\" has been created!"
      redirect_to edit_polymorphic_path([@organization, @assignment, @task])
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      flash[:success] = "Task \"#{@task.title}\" updated"
      redirect_to edit_polymorphic_path([@organization, @assignment, @task])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    flash[:success] = "\"#{@task.title}\" has been deleted"
    redirect_to [:edit, @organization, @assignment]
  end

  private

  def set_assignment
    if params[:assignment_id]
      @assignment = Assignment.find_by!(slug: params[:assignment_id])
    elsif params[:group_assignment_id]
      @assignment = GroupAssignment.find_by!(slug: params[:group_assignment_id])
    end
  end

  def set_task
    @task = @assignment.tasks.find_by!(position: params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :body)
  end
end
