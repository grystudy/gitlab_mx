class Projects::ReleasesController < Projects::ApplicationController
  before_filter :releaserepo

  def show
    rls = releaserepo.tags.reverse
    @releases = Kaminari.paginate_array(rls).page(params[:page]).per(5)
  end

  private
  def releaserepo
    @releaserepo ||= Repository.new(project.path_with_namespace+".wiki")
  end
end
