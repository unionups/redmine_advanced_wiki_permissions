# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require 'capybara/rails'

module IntegrationTestHelper
  def login_as(user = "existing", password = "existing")
    visit "/logout" # Make sure the session is cleared

    visit "/login"
    fill_in 'Login', :with => user
    fill_in 'Password', :with => password
    click_button 'Login'
    assert_response :success
    assert User.current.logged?
  end

  def visit_wiki_page(project, wiki_page)
    visit "/projects/#{project.identifier}/wiki/#{wiki_page.title}"
    assert_response :success
  end
end

class ActionController::TestCase
  include IntegrationTestHelper
  include Capybara::DSL
end

