class CreateWikiPagePermissions < ActiveRecord::Migration
  def self.up
    create_table :wiki_page_permissions do |t|
      t.column :principal_id, :integer
      t.column :wiki_page_id, :integer
      t.column :permissions, :string
    end
  end

  def self.down
    drop_table :wiki_page_permissions
  end
end

