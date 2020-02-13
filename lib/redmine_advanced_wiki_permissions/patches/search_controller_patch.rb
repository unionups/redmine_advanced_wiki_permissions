module RedmineAdvancedWikiPermissions
  module Patches
    module SearchControllerPatch
        def index
          super
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
      # end
    end
  end
end

SearchController.send :prepend, RedmineAdvancedWikiPermissions::Patches::SearchControllerPatch