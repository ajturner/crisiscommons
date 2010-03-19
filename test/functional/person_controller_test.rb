require File.dirname(__FILE__) + '/../test_helper'

class PersonControllerTest < ActionController::TestCase
  fixtures :users, :pages, :sites, :profiles

  def test_show_not_logged_in_public_profile_visible
    users(:red).profiles.public.update_attribute(:may_see, true)
    get :show, :id => users(:red).to_param
    assert_response :success
    assert_nil assigns(:pages).find { |p| !p.public? }
    # test for #1901
    assert_select '.no-third-level'
  end

  def test_show_not_logged_in
    get :show, :id => users(:red).to_param
    assert_response :success
    assert_select "p", :text => /Sorry, we were unable to locate/
  end

  def test_show_logged_in
    login_as :dolphin
    get :show, :id => users(:orange).to_param
    assert_response :success
    assert_nil assigns(:pages).find { |p| !(p.public? or users(:dolphin).may?(:view, p)) }
    # test for #1901
    assert_select '.no-third-level'
  end

  def test_search_not_logged_in
    # note: if yellow doesn't have a public profile, you will get weird results.
    get :search, :id => users(:yellow).to_param
    assert_response :success
    assert_not_nil assigns(:pages)
    assert_nil assigns(:pages).find { |p| !p.public? }
  end

  def test_search_logged_in
    login_as :penguin
    get :search, :id => users(:green).to_param
    assert_not_nil assigns(:pages)
    assert_response :success
    assert_nil assigns(:pages).find { |p| !(p.public? or users(:penguin).may?(:view, p)) }
  end

  def test_tasks_not_logged_in
    get :tasks, :id => users(:blue).to_param
    assert_response :success
#    assert_template 'tasks'
    assert_nil assigns(:pages).find { |p| !p.is_a?(TaskListPage) }
    assert_nil assigns(:pages).find { |p| !p.public? }
  end

  def test_tasks_logged_in
    login_as :quentin
    get :tasks, :id => users(:purple).to_param
    assert_response :success
#    assert_template 'tasks'
    assert_nil assigns(:pages).find { |p| !p.is_a?(TaskListPage) }
    assert_nil assigns(:pages).find { |p| !users(:quentin).may?(:view, p) }
  end
end
