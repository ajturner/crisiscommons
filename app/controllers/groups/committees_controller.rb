class Groups::CommitteesController < GroupsController

  def new
    @parent = get_parent
    @group = Committee.new
    @second_nav = 'administration'
    @third_nav = 'settings'
    @fourth_nav = 'new committee'
  end

  def create
    @parent = get_parent
    @group = Committee.new params[:group]
    @group.created_by = current_user  # needed for the activity
    @group.save!
    @parent.add_committee!(@group)
    group_created_success
  rescue Exception => exc
    flash_message_now :exception => exc
    render :template => 'groups/new'
    @second_nav = 'administration'
    @third_nav = 'settings'
  end

  protected

  def authorized?
    true
  end

  def context
    group_settings_context if action_name == "new" || action_name == "create"
  end

  def get_parent
    parent = Group.find_by_name(params[:id])
    unless may_create_subcommittees?(parent)
      raise PermissionDenied.new(I18n.t(:dont_have_permission_to_create_committees, :group => parent.name))
    end
    parent
  end

end

