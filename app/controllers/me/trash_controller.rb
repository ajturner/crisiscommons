class Me::TrashController < Me::BaseController

  helper :action_bar
  def search
    if request.post?
      path = parse_filter_path(params[:search])
      redirect_to url_for(:controller => '/me/pages/trash', :action => 'search', :path => nil) + path
    else
      list
    end
  end

  def index
    list
  end

  def list
    @path.default_sort('updated_at')
    full_url = url_for(:controller => '/me/pages/trash', :action => 'search', :path => @path)

    @pages = Page.paginate_by_path(@path.merge(:admin => current_user.id), options_for_me(:flow => :deleted).merge(pagination_params))
    @second_nav = 'pages'
    handle_rss(
      :link => full_url,
      :title => 'Crabgrass Trash',
      :image => avatar_url(:id => @user.avatar_id||0, :size => 'huge')
    ) or render(:action => 'list')
  end

  # post required
  def update
    pages = params[:pages]
    if pages
      pages.each do |page_id|
        page = Page.find_by_id(page_id)
        if page
          if params[:undelete] and may_undelete_page?(page)
            page.undelete
          elsif params[:remove] and may_remove_page?(page)
            page.destroy
            ## add more actions here later
          end
        end
      end
    end
    if params[:path]
      redirect_to :action => 'search', :path => params[:path]
    else
      redirect_to :action => nil, :path => nil
    end
  end

  protected

  def may_undelete_page?(page)
    current_user.may?(:admin, page)
  end

  def may_remove_page?(page)
    current_user.may?(:delete, page)
  end

  def context
    super
    add_context I18n.t(:me_trash_link), url_for(:controller => '/me/pages/trash', :action => 'search', :path => params[:path])
  end

end
