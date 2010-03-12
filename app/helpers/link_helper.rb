#
# Here lies many helpers for making links and buttons.
#
# Traditionally, all POSTS are done with submit buttons and all
# GETS are done with links. On occasion, we might want to mix it up.
# These helpers let us do that, and use the accesskey facility in gecko
# browsers.
#
# Submitting forms
# ----------------
#
# submit_tag
# The normal built in function. do :class => 'button' or :class => 'link' to
# change how it looks.
#
# submit_link
# a link which will submit the form.
#
#
# The multiple submit buttons
# ---------------------------
#
# Normally, when a form is submitted it is simply submitted. Often, we would
# like to be able to have two different submit buttons. Here is how you would
# do that:
#
#   submit_tag 'Save', :name => 'save'
#   submit_tag 'Cancel', :name => 'cancel'
#
# In the controller, then test for params[:save] or params[:cancel]. The
# values will be useless (set to 'Save' and 'Cancel' in this case, but it could
# be anything if using translations). Normally, setting :name does not work for
# ajax forms. This is changed with a modification of the default submit_tag
# function. All the submit helpers accept the name parameter.
#
#
# Creating get requests
# ---------------------
#
# link_to (built-in)
# this is the built in function for links, no change here.
#
# button_to (built-in)
# pass method get to options.
# eg. button_to('label', {:action => 'xxx', :method => 'get'}, {:class => 'whatever'})
#
#
# Creating post requests
# ------------------------
#
# button_to (built in)
# creates a button that creates a post request.
#
# link_to (built-in)
# pass with html_options {:method => 'post'}
# eg: link_to 'destroy', {:action => 'destroy'}, {:method => 'post'}
#
#
# Creating ajax requests
# -----------------------
#
# link_to_remote (built in)
#
# button_to_remote (built in)
#
#
module LinkHelper

  # link to if and only if...
  # like link_to_if, but return nil if the condition is false
  def link_to_iff(condition, name, options = {}, html_options = {}, &block)
    if condition
      link_to(name, options, html_options, &block)
    else
      nil
    end
  end

  ### SUBMITS ###

  def submit_link(label, options={})
    name = options.delete(:name) || 'commit'
    value = options.delete(:value) || label
    accesskey = shortcut_key label
    onclick = %Q<submitForm(this, "#{name}", "#{value}");>
    if options[:confirm]
      onclick = %Q<if(confirm("#{options[:confirm]}")){#{onclick};}else{return
 false;}>
    end
    %Q(<span class='#{options[:class]}'><a href='#' onclick='#{onclick}' style
='#{options[:style]}' class='#{options[:class]}' accesskey='#{accesskey}'>#{
label}</a></span>)
  end

  ### AJAX ###

  # def button_to_remote()
  #  to be written
  # end

  ### UTIL ###

  def shortcut_key(label)
    label.gsub!(/\[(.)\]/, '<u>\1</u>')
    /<u>(.)<\/u>/.match(label).to_a[1]
  end




  # just like link_to, but sets the <a> tag to have class 'active'
  # if last argument is true or if the url is in the form of a hash
  # and the current params match this hash.
  def link_to_active(link_label, url_hash, active=nil)
    active = active || url_active?(url_hash)
    selected_class = active ? 'active' : ''
    link_to(link_label,url_hash, :class => selected_class)
  end

  #
  # *NEWUI
  #
  # return class if strings match the current action.
  # the default class current
  # used in groups/navigation/_menu
  #
  def current_class(link, ccs_class = 'current')
    if link == request.path
      css_class
    else
      ''
    end
  end

  # like link_to_remote, but sets the class to be 'active' if the link is
  # active (:active => true)
  def link_to_remote_active(link_label, options, html_options={})
    active = options.delete(:active) || html_options.delete(:active)
    selected_class = active ? 'active' : ''
    html_options[:class] = [html_options[:class], selected_class].combine
    if options[:icon] or html_options[:icon]
      link_to_remote_with_icon(link_label, options, html_options)
    else
      link_to_remote(link_label, options, html_options)
    end
  end

  # returns true if the current params matches url_hash
  def url_active?(url_hash)
    return false unless url_hash.is_a? Hash

    url_hash[:action] ||= 'index'

    selected = true
    url_hash.each do |key, value|
      selected = compare_param(params[key], value)
      break unless selected
    end
    selected
  end

  ##
  ## CREATION
  ##

  # returns a link to the create action for the type given.
  def link_to_create(type)
    if type == :groups
      if may_create_group?
        link_to(I18n.t(:create_a_group).upcase, groups_url(:action => 'new'))
      end
    elsif type == :networks
      if may_create_network?
        link_to(I18n.t(:create_a_network).upcase, networks_url(:action => 'new'))
      end
    end
  end

  private

  def compare_param(a,b)
    a = a.to_param
    b = b.to_param
    if b.empty?
      true
    elsif a.empty?
      false
    elsif a == b
      true
    elsif a.is_a?(Array) or b.is_a?(Array)
      a = a.to_a.sort
      b = b.to_a.sort
      b == a
    elsif a.sub(/^\//, '') == b.sub(/^\//, '')
      true # a controller of '/groups' should match 'groups'
    else
      false
    end
  end

end
