module RedmineAdvancedWikiPermissions
    class Hooks < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        html =  stylesheet_link_tag( :redmine_advanced_wiki_permissions, :plugin => "redmine_advanced_wiki_permissions", :media => "screen")
        html << javascript_include_tag(:redmine_advanced_wiki_permissions, :plugin => 'redmine_advanced_wiki_permissions')
      end
    end
end

