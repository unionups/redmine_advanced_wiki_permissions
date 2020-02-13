class CreateDelegatePermissions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :delegate_permissions do |t|
      t.column :user_id, :integer
      t.column :project_id, :integer
      t.column :permitted, :string
      t.column :banned, :string
    end
  end

  def self.down
    drop_table :delegate_permissions
  end
end

