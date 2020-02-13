module RedmineAdvancedWikiPermissions
  module Patches
    module WikiPagePrependPatch

      def visible?(user=User.current)
        if wiki.project &&
           wiki.project.module_enabled?('wiki') &&
           wiki.project.module_enabled?('redmine_advanced_wiki_permissions')
          return !user.nil? && user.wiki_allowed_to?(self, :view_wiki_pages)
        end
        super
      end

      # Returns true if usr is allowed to edit the page, otherwise false
      def editable_by?(usr)
        if wiki.project &&
           wiki.project.module_enabled?('wiki') &&
           wiki.project.module_enabled?('redmine_advanced_wiki_permissions')
          !protected? || usr.wiki_allowed_to?(self, :protect_wiki_pages)
        else
          !protected? || usr.allowed_to?(:protect_wiki_pages, wiki.project)
        end
      end

      def ignore_permissions?
        return true if ignore_permissions
        false
      end

      def principals_with_permissions
        principals = permissions.map{|wpp| Principal.find(wpp.principal_id)}
      end
    end
    module WikiPagePatch
      extend ActiveSupport::Concern
      included do
        validates_inclusion_of :ignore_permissions, :in => [true, false], :allow_nil => true
        has_many :permissions, :class_name => 'WikiPagePermission', :dependent => :destroy
      end
    end
  end
end

WikiPage.send :include, RedmineAdvancedWikiPermissions::Patches::WikiPagePatch
WikiPage.send :prepend, RedmineAdvancedWikiPermissions::Patches::WikiPagePrependPatch