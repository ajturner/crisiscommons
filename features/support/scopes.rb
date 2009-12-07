module ScopeHelpers
  # Maps a name of a section to a CSS selector. Used by the
  #
  #   Then /^I should see \/([^\/]*)\/ within "([^\"]*)"$/ do |regexp, scope|
  #
  # step definition in webrat_steps.rb
  #
  def selector_for(scope)
    case scope

    when /the info box/
      '.info_box'
    when /the page sidebar/
      '#page_sidebar'
    else
      # use the scope as it is
      scope
    end
  end
end

World(ScopeHelpers)
