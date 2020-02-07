module RedmineAdvancedWikiPermissions
  module Hooks
    class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        protocol = context[:request].ssl? ? 'https' : 'http'
          return stylesheet_link_tag("redmine_advanced_wiki_permissions.css", :plugin => "redmine_advanced_wiki_permissions", :media => "screen")
      end
    end
  end
end
