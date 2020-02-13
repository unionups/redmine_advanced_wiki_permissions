module RedmineAdvancedWikiPermissions
  module Patches
    module ApplicationHelperPrependPatch
      def link_to_if_authorized(name, options = {}, html_options = nil, *parameters_for_method_reference)
        if @project &&
           @project.module_enabled?('wiki') &&
           @project.module_enabled?('redmine_advanced_wiki_permissions') &&
           @page.class == WikiPage
          if authorize_for_wiki(@page, options[:action])
            link_to(name, options, html_options, *parameters_for_method_reference)
          end
        else
          super
        end
      end

      def render_page_hierarchy(pages, node=nil, options={})
        pages[node].reject!{|p| !User.current.wiki_allowed_to?(p, :view_wiki_pages)} if pages[node]
        super
      end
    end
    module ApplicationHelperPatch
      extend ActiveSupport::Concern
      included do
        def authorize_for_wiki(page, action)
          User.current.wiki_allowed_to?(page, action)
        end
      end
    end
  end
end
ApplicationHelper.send :include, RedmineAdvancedWikiPermissions::Patches::ApplicationHelperPatch
ApplicationHelper.send :prepend, RedmineAdvancedWikiPermissions::Patches::ApplicationHelperPrependPatch