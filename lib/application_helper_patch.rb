module ApplicationHelperPatch
  def self.included(base)
    base.class_eval do
      alias_method :link_to_if_authorized_without_wiki_permissions,
                   :link_to_if_authorized unless method_defined? :link_to_if_authorized_without_wiki_permissions
      alias_method :render_page_hierarchy_without_wiki_permissions,
                   :render_page_hierarchy unless method_defined? :render_page_hierarchy_without_wiki_permissions

      def link_to_if_authorized(name, options = {}, html_options = nil, *parameters_for_method_reference)
        if @project &&
           @project.module_enabled?('wiki') &&
           @project.module_enabled?('redmine_advanced_wiki_permissions') &&
           @page.class == WikiPage
          if authorize_for_wiki(@page, options[:action])
            link_to(name, options, html_options, *parameters_for_method_reference)
          end
        else
          link_to_if_authorized_without_wiki_permissions(name, options, html_options, *parameters_for_method_reference)
        end
      end

      def render_page_hierarchy(pages, node=nil, options={})
        pages[node].reject!{|p| !User.current.wiki_allowed_to?(p, :view_wiki_pages)} if pages[node]
        render_page_hierarchy_without_wiki_permissions(pages, node, options)
      end

      def authorize_for_wiki(page, action)
        User.current.wiki_allowed_to?(page, action)
      end
    end
  end
end
