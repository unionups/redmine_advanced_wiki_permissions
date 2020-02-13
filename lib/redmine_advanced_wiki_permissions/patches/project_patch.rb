module RedmineAdvancedWikiPermissions
  module Patches
    module ProjectPatch
      extend ActiveSupport::Concern
      included do
      	has_many :delegate_permissions, :dependent => :destroy
      end
    end
  end
end

Project.send :include, RedmineAdvancedWikiPermissions::Patches::ProjectPatch