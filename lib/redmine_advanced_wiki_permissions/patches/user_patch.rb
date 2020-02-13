require_dependency 'principal'
module RedmineAdvancedWikiPermissions
  module Patches
    module UserPrependPatch
      def allowed_to?(action, context, options = { })
        if context &&
           context.is_a?(Project) &&
           context.module_enabled?('wiki') &&
           context.module_enabled?('redmine_advanced_wiki_permissions') &&
           action.class == Hash &&
           action[:controller] == 'wiki'
          return true
        end
        super(action, context, options)
      end
    end

    module UserPatch
      extend ActiveSupport::Concern
      included do
        has_many :delegate_permissions, :dependent => :destroy
        alias_method :allowed_to_without_wiki_permissions?,
                     :allowed_to? unless method_defined? :allowed_to_without_wiki_permissions?

        def wiki_allowed_to?(target, action)
          return true if admin?
          if target.class == WikiPage
            action = fix_action_for_wiki_page_permissions(action)
            # Current user has permission for this page
            if self.permission_exist?(target)
              permission = permission_for(target)
              return true if permission.permissions.include?(action)
              return false if permission.bans.include?(action)
            end
            # Find permissions for groups on this page
            wpps = target.permissions.map{|wpp| wpp if wpp.principal.class.to_s == 'Group' && wpp.actual_for?(self)}.compact
            allowed_users = wpps.map{|wpp| wpp.principal.users if wpp.has_permission?(action)}.flatten.compact.uniq
            return true if allowed_users.include?(self)
            prohibited_users = wpps.map{|wpp| wpp.principal.users if wpp.has_ban?(action)}.flatten.compact.uniq
            return false if prohibited_users.include?(self)
            # return true if !target.ignore_permissions? && allowed_to_without_wiki_permissions?(action, target.project)
            return true if !target.ignore_permissions? && allowed_to_without_wiki_permissions?(action, target.project)
            return false
          elsif target.class == Project
            target.wiki.pages.each do |page|
              return false unless wiki_allowed_to?(page, :export_wiki_pages)
            end
            return true
          end
        end

        def allowed_to_manage_wiki_rights?(target)
          return true if admin?
          if target.class == WikiPage
            return true if wiki_manager?(target.project)
            return true if delegate_permission_exist?(target.project) && wiki_allowed_to?(target, :delegate_permissions)
          elsif target.class == Project
            return true if wiki_manager?(target)
            return true if delegate_permission_exist?(target)
          end
          false
        end

        def wiki_manager?(project)
          self.allowed_to?(:manage_wiki_rights, project)
        end

        def permissions_from_groups(wiki_page)
          permissions = []
          self.groups.each do |group|
            permissions |= group.permissions_from(wiki_page.project)
            if group.permission_exist?(wiki_page) && group.permission_for(wiki_page).actual_for?(self)
              permissions -= group.permission_for(wiki_page).bans
              permissions |= group.permission_for(wiki_page).permissions
            end
          end
          WikiPagePermission::PERMS & permissions
        end

        def delegate_permission_exist?(project)
          return true if delegate_permission_for(project)
          false
        end

        def delegate_permission_for(project)
          project.delegate_permissions.find_by(user_id: self.id)
        end

        def principals_for_delegate(project)
          return render_403 unless allowed_to_manage_wiki_rights?(project)
          return Principal.active.order('type, login, lastname ASC').first(100) if wiki_manager?(project)#find(:all, :limit => 100, :order => 'type, login, lastname ASC') if wiki_manager?(project)
          delegate_permission_for(project).principals_for_delegate[0..100]
        end

        private

        def fix_action_for_wiki_page_permissions(action)
          case action
          when 'edit'
            return :edit_wiki_pages
          when 'history'
            return :view_wiki_edits
          when 'destroy'
            return :delete_wiki_pages
          when 'rename'
            return :rename_wiki_pages
          when 'protect'
            return :protect_wiki_pages
          else
            return action
          end
        end
        
      end
    end
  end
end

User.send :include, RedmineAdvancedWikiPermissions::Patches::UserPatch
User.send :prepend, RedmineAdvancedWikiPermissions::Patches::UserPrependPatch