module ProjectsHelperPatch
  def self.included(base)
    base.class_eval do
      alias_method :project_settings_tabs_without_wiki_permissions,
                   :project_settings_tabs unless method_defined? :project_settings_tabs_without_wiki_permissions

      def project_settings_tabs
        tabs = project_settings_tabs_without_wiki_permissions
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
