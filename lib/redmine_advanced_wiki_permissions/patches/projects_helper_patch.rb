module RedmineAdvancedWikiPermissions
  module Patches
    module ProjectsHelperPatch
      def project_settings_tabs
        tabs = super
        tab = { :name => 'manage_wiki_rights',
                :action => :manage_wiki_rights,
                :partial => 'projects/settings/manage_wiki_rights',
                :label => :label_delegate_wiki_rights
              }
        tabs << tab if @project &&
                       @project.module_enabled?('wiki') &&
                       @project.module_enabled?('redmine_advanced_wiki_permissions') &&
                       User.current.wiki_allowed_to?(@project, :manage_wiki_rights)
        return tabs
      end
    end
  end
end

ProjectsHelper.send :prepend, RedmineAdvancedWikiPermissions::Patches::ProjectsHelperPatch