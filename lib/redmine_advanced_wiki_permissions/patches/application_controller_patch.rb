module RedmineAdvancedWikiPermissions
  module Patches
    module ApplicationControllerPatch
        def authorize(ctrl = params[:controller], action = params[:action], global = false)
          return super if defined?(super)

          if @project &&
             @project.module_enabled?('wiki') &&
             @project.module_enabled?('redmine_advanced_wiki_permissions') &&
             ctrl == 'wikis'
            User.current.wiki_allowed_to?(@project, :manage_wiki)
          else
            super(ctrl, action, global)
          end
        end 
    end
  end
end

ApplicationController.send :prepend, RedmineAdvancedWikiPermissions::Patches::ApplicationControllerPatch