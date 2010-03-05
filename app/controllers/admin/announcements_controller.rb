class Admin::AnnouncementsController < Admin::BaseController
  verify :method => :post, :only => [:update]

  permissions 'admin/announcements'
  helper 'base_page/share'

  def index
    @pages = Page.paginate_by_path('descending/created_at', pagination_params.merge({:flow => :announcement}))
  end

  def new
    @page = AnnouncementPage.new
    @groups = Group.all
  end

  def edit
    @page = AnnouncementPage.find(params[:id])
  end

  def destroy
    # @page is loaded in may_destroy_announcemets
    @page.destroy
    redirect_to announcements_path
  end

end

