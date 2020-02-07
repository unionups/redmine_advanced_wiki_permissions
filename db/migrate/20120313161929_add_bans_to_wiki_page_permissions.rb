class AddBansToWikiPagePermissions < ActiveRecord::Migration
  def self.up
    add_column :wiki_page_permissions, :bans, :string
  end

  def self.down
    remove_column :wiki_page_permissions, :bans
  end
end

