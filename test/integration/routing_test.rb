require File.dirname(__FILE__) + '/../test_helper'

class RoutingTest < ActionController::IntegrationTest
  context "wiki_controller" do
    should_route :get,
                 '/projects/projectname/wiki/Wiki/permissions',
                 { :controller => 'wiki',
                   :action => :permissions,
                   :project_id => 'projectname',
                   :id => 'Wiki' }
  end

  context "wiki_permissions_controller" do
    should_route :post,
                 '/projects/projectname/wiki/Wiki/permissions/destroy',
                 { :controller => 'wiki_permissions',
                   :action => :destroy,
                   :project_id => 'projectname',
                   :id => 'Wiki' }

    should_route :post,
                 '/projects/projectname/wiki/Wiki/permissions/update',
                 { :controller => 'wiki_permissions',
                   :action => :update,
                   :project_id => 'projectname',
                   :id => 'Wiki' }
  end
end

