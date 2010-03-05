# these are posts on a persons wall discussion
class People::PublicMessagesController < People::BaseController
  permissions 'public_messages'

  before_filter :fetch_post, :login_required

  helper 'wall_posts'
  stylesheet 'messages'

  #
  # display a list of recent message activity
  #
  def index
    @posts = @user.wall_discussion.posts.by_created_at.paginate(pagination_params)
  end

  def update
    create
  end

  def show
    render_not_found unless @post
  end

  def destroy
    if @post
      @post.destroy
      redirect_to url_for_user(@user)
    else
      render_not_found
    end
  end

  def create
    @post = PublicPost.create do |post|
      post.body = params[:post][:body]
      post.discussion = @user.wall_discussion
      post.user = current_user
      post.recipient = @user
      post.body_html = post.lite_html
    end
  rescue ActiveRecord::RecordInvalid => exc
    flash_message :exception => exc
  ensure
    redirect_to url_for_user(@user)
  end

  protected

  def fetch_post
    @post = @user.wall_discussion.posts.find_by_id(params[:id]) if params[:id]
  end

  def context
    super
    add_context(I18n.t(:messages), person_messages_url)
    if action?(:show)
      add_context(h(@post.body[0..48]), person_message_path(@user, @post))
    end
  end

end
