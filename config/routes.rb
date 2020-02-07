ActionController::Routing::Routes.draw do |map|
  map.connect 'projects/:project_id/wiki/:id/permissions', :controller => 'wiki', :action => 'permissions'
  map.connect 'projects/:project_id/wiki/:id/permissions/destroy', :controller => 'wiki_permissions', :action => 'destroy'
  map.connect 'projects/:project_id/wiki/:id/permissions/update', :controller => 'wiki_permissions', :action => 'update'
  map.connect 'projects/:project_id/wiki/:id/permissions/autocomplete_for_member', :controller => 'wiki_permissions', :action => 'autocomplete_for_member'
  map.connect 'projects/:project_id/wiki/:id/ignore_permissions', :controller => 'wiki', :action => 'ignore_permissions'
end

