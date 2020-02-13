module RedmineAdvancedWikiPermissions
  module Patches
    module PrincipalPatch
      extend ActiveSupport::Concern

      included do

        has_many :permissions, :class_name => 'WikiPagePermission', :dependent => :destroy

        def permissions_from(project)
          return WikiPagePermission::PERMS if self.class == User && self.wiki_manager?(project)
          permissions = []
          roles_from(project).each do |role|
            permissions |= role.permissions.find_all{|p| p if p.to_s.include?('wiki')}
          end
          WikiPagePermission::PERMS & permissions
        end

        def roles_from(project)
          roles = []
          return roles unless project && project.active?
          membership = memberships.detect {|m| m.project_id == project.id}
          roles = membership.roles if membership
          roles
        end

        def permission_exist?(wiki_page)
          return true if permission_for(wiki_page)
          false
        end

        def permission_for(wiki_page)
          wiki_page.permissions.find_by(principal_id: self.id)
        end
      end
    end
  end
end

Principal.send :include, RedmineAdvancedWikiPermissions::Patches::PrincipalPatch