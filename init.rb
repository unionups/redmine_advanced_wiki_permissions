require 'redmine'
require 'dispatcher'

require_dependency 'view_layouts_base_html_head_hook'

Redmine::Plugin.register :redmine_advanced_wiki_permissions do
  name 'Redmine Advanced Wiki Permissions plugin'
  author 'Anton Tsapov'
  description 'This is plugin add permissions for every wiki page in project'
  version '0.0.2'
  url 'http://nexstep.ua/'

  project_module :redmine_advanced_wiki_permissions do
    permission :manage_wiki_rights, { :wiki => :permissions }
  end
end

Dispatcher.to_prepare do
  begin
    require_dependency 'application'
  rescue LoadError
    require_dependency 'application_controller'
  end

  require_dependency 'application_controller'
  require_dependency 'search_controller'
  require_dependency 'wiki_controller'
  require_dependency 'application_helper'
  require_dependency 'projects_helper'
  require_dependency 'group'
  require_dependency 'mailer'
  require_dependency 'principal'
  require_dependency 'project'
  require_dependency 'user'
  require_dependency 'wiki_page'

  ApplicationController.send(:include, ApplicationControllerPatch)
  SearchController.send(:include, SearchControllerPatch)
  WikiController.send(:include, WikiControllerPatch)
  ApplicationHelper.send(:include, ApplicationHelperPatch)
  ProjectsHelper.send(:include, ProjectsHelperPatch)
  Group.send(:include, GroupPatch)
  Mailer.send(:include, MailerPatch)
  Principal.send(:include, PrincipalPatch)
  Project.send(:include, ProjectPatch)
  User.send(:include, UserPatch)
  WikiPage.send(:include, WikiPagePatch)
end
