module ApplicationControllerPatch
  def self.included(base)
    base.class_eval do
      alias_method :authorize_without_wiki_permissions,
                   :authorize unless method_defined? :authorize_without_wiki_permissions

      def authorize(ctrl = params[:controller], action = params[:action], global = false)
        if @project &&
           @project.module_enabled?('wiki') &&
           @project.module_enabled?('redmine_advanced_wiki_permissions') &&
           ctrl == 'wikis'
          User.current.wiki_allowed_to?(@project, :manage_wiki)
        else
          authorize_without_wiki_permissions(ctrl, action, global)
        end
      end

    end
  end
end
