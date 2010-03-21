=begin

 WikiController

 This is the controller for the in-place wiki editor, not for the
 the wiki page type (wiki_page_controller.rb).

 Everything here is entirely ajax, for now.

=end

class WikiController < ApplicationController
  helper :wiki
  permissions 'wiki'

  include ControllerExtension::WikiRenderer
  include ControllerExtension::WikiPopup

  before_filter :login_required, :except => [:show, :image_popup_show, :link_popup_show, :image_popup_upload, :map_popup_show]
  before_filter :fetch_wiki
  before_filter :setup_wiki_rendering

  # show the rendered wiki
  def show
  end

  # show the entire edit form
  def edit
    if @public and @private
      @private.lock!(:document, current_user) if @private.document_open_for?(current_user)
      @public.lock!(:document, current_user) if @public.document_open_for?(current_user)
    else
      @wiki.lock!(:document, current_user) if @wiki.document_open_for?(current_user)
    end
  end

  # show a wiki body from an old version
  def old_version
    # XHR
    @showing_old_version = @wiki.versions[params[:old_version].to_i - 1]

    @wiki.body = @showing_old_version.body
    @wiki.body_html = @showing_old_version.body_html

    render :action => 'edit'
  end

  # a re-edit called from preview, just one area.
  def edit_area
    return render(:action => 'done') if params[:close]
    @wiki.lock!(:document, current_user) if @wiki.document_open_for?(current_user)
  end

  # save the wiki show the preview
  def save
    return cancel if params[:cancel]
    return break_lock if params[:break_lock]

    begin
      @wiki.update_document!(current_user, params[:version], params[:body])
      unlock_for_current_user
    rescue Exception => exc
      @message = exc.to_s
      return render(:action => 'error')
    end
  end

  # unlock everything and show the rendered wiki
  def done
    unlock_for_current_user
    if @public and @private
      if @private.body.nil? or @private.body == ''
        @wiki = @public
      else
        @wiki = @private
      end
    end
  end

  protected

  def break_lock
    if @public and @private
      @private.unlock!(:document, current_user, :force => true)
      @public.unlock!(:document, current_user, :force => true)

      @private.lock!(:document, current_user)
      @public.lock!(:document, current_user)
    else
      @wiki.unlock!(:document, current_user, :force => true)
      @wiki.lock!(:document, current_user)
    end

    render(:action => 'edit')
  end

  def cancel
    unlock_for_current_user
    render :action => 'done'
  end

  def unlock_for_current_user
    if @public and @private
      @private.unlock!(:document, current_user) if @private.document_open_for?(current_user)
      @public.unlock!(:document, current_user) if @public.document_open_for?(current_user)
    else
      @wiki.unlock!(:document, current_user) if @wiki.document_open_for?(current_user)
    end
  end

  def fetch_wiki
    @group ||= Group.find(params[:group_id])
    if params[:wiki_id] and !params[:profile_id]
      profile = @group.profiles.find_by_wiki_id(params[:wiki_id])
      @wiki = profile.wiki || profile.create_wiki(:user => current_user)
    elsif params[:profile_id]
      @profile = @group.profiles.find(params[:profile_id])
      @public = @group.profiles.public.wiki || @group.profiles.public.create_wiki(:user => current_user)
      @private = @group.profiles.private.wiki || @group.profiles.private.create_wiki(:user => current_user)

      @wiki = @public if params[:wiki_id] == @public.id.to_s
      @wiki = @private if params[:wiki_id] == @private.id.to_s
    end
  end

  def setup_wiki_rendering
    return unless @wiki
    @wiki.render_body_html_proc {|body| render_wiki_html(body, @group.name)}
  end

  # which images should be displayed in the image upload popup
  def image_popup_visible_images
    Asset.visible_to(current_user, @group).media_type(:image).most_recent.find(:all, :limit=>20)
  end

  def authorized?
    @group = Group.find(params[:group_id])
    may_action?(params[:action], @group)
  end
end
