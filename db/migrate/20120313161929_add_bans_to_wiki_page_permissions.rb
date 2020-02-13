class AddBansToWikiPagePermissions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :wiki_page_permissions, :bans, :string
  end

  def self.down
    remove_column :wiki_page_permissions, :bans
  end
end

