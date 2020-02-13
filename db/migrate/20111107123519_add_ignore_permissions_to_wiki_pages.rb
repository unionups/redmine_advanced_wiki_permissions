class AddIgnorePermissionsToWikiPages < ActiveRecord::Migration[4.2]
  def self.up
    add_column :wiki_pages, :ignore_permissions, :boolean
  end

  def self.down
    remove_column :wiki_pages, :ignore_permissions
  end
end

