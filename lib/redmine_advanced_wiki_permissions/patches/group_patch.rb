require_dependency 'principal'
module RedmineAdvancedWikiPermissions
  module Patches
    module GroupPatch
      extend ActiveSupport::Concern
      included do
        def wiki_allowed_to?(wiki_page, action)
          permission = wiki_page.permissions.find_by( principal_id: self.id )
          if permission
            return true if permission.permissions.include?(action)
            return false if permission.bans.include?(action)
            return true if !wiki_page.ignore_permissions? && allowed_to_with_project_roles?(wiki_page.project, action)
            return false
          end
        end

        def allowed_to_with_project_roles?(project, action)
          self.permissions_from(project).include?(action)
        end
      end
    end
  end
end

Group.send :include , RedmineAdvancedWikiPermissions::Patches::GroupPatch