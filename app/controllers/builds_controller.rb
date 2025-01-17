# frozen_string_literal: true
class BuildsController < ApplicationController
  include CurrentProject

  before_action :authorize_resource!
  before_action :enforce_disabled_docker_builds, only: [:new, :create, :build_docker_image]
  before_action :find_build, only: [:show, :build_docker_image, :edit, :update]

  def index
    @builds = current_project.builds.order('id desc').page(page)
    if search = params[:search]
      @builds = @builds.where(search.permit(*Build.column_names))
    end

    respond_to do |format|
      format.html
      format.json { render json: @builds }
    end
  end

  def new
    @build = current_project.builds.build
  end

  def create
    @build = new_or_modified_build
    @build.creator = current_user
    start_docker_build if saved = @build.save
    respond_to_save saved, :created, :new
  end

  def show
    @project = @build.project
  end

  def edit
  end

  def update
    success = @build.update_attributes(edit_build_params)
    respond_to_save success, :ok, :edit
  end

  def build_docker_image
    start_docker_build
    respond_to do |format|
      format.html do
        redirect_to [current_project, @build]
      end

      format.json do
        render json: {}, status: :ok
      end
    end
  end

  private

  def find_build
    @build = Build.find(params[:id])
  end

  def new_build_params
    params.require(:build).permit(*Build::ASSIGNABLE_KEYS)
  end

  def edit_build_params
    params.require(:build).permit(:name, :description)
  end

  def start_docker_build
    DockerBuilderService.new(@build).run(push: true)
  end

  def new_or_modified_build
    if old_build = current_project.builds.where(git_sha: git_sha).last
      old_build.update_attributes(new_build_params)
      old_build
    else
      current_project.builds.build(new_build_params)
    end
  end

  def respond_to_save(saved, status, template)
    respond_to do |format|
      format.html do
        if saved
          redirect_to [current_project, @build]
        else
          render template, status: :unprocessable_entity
        end
      end

      format.json do
        render json: {}, status: (saved ? status : :unprocessable_entity)
      end
    end
  end

  def git_sha
    @git_sha ||= current_project.repository.commit_from_ref(new_build_params[:git_ref])
  end

  def enforce_disabled_docker_builds
    return unless @project.docker_image_building_disabled?
    redirect_to project_builds_path(@project), alert: "Image building is disabled, they must be created via the api."
  end
end
