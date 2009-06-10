class Admin::AnnouncementsController < Admin::BaseController
  verify :method => :post, :only => [:update]
  
  def index
    @active = 'edit_announcements'
    @pages = Page.paginate_by_path('descending/created_at', :page => params[:page], :flow => :announcement)
  end
  
  def new
    @active = 'create_announcements'
    @page = AnnouncementPage.new
    @groups = Group.all
  end
  
  def edit
    @active = 'edit_announcements'
    @page = AnnouncementPage.find(params[:id])
  end
  
  def destroy
    @page = Page.find_by_id(params[:id])
    @page.destroy
    redirect_to announcements_path
  end

end

