require File.dirname(__FILE__) + '/../test_helper'

class WikiControllerTest < ActionController::TestCase
  context "routing" do
    should_route :get,
                 '/projects/projectname/wiki/Wiki/permissions',
                 { :controller => 'wiki',
                   :action => :permissions,
                   :project_id => 'projectname',
                   :id => 'Wiki' }
  end
end

