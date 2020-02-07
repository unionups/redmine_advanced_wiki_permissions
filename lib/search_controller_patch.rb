module SearchControllerPatch
  def self.included(base)
    base.class_eval do
      alias_method :index_without_wiki_permissions,
                   :index unless method_defined? :index_without_wiki_permissions

      def index
        index_without_wiki_permissions
        if @results
          @results.delete_if do |result|
            result.class == WikiPage &&
              result.project.module_enabled?('wiki') &&
              result.project.module_enabled?('redmine_advanced_wiki_permissions') &&
              !User.current.wiki_allowed_to?(result, :view_wiki_pages)
          end
          @results_by_type['wiki_pages'] = @results.count
        end
      end

    end
  end
end
