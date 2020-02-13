class AddDelegatePermissionIdToWikiPagePermissions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :wiki_page_permissions, :delegate_permission_id, :integer
  end

  def self.down
    remove_column :wiki_page_permissions, :delegate_permission_id
  end
end

