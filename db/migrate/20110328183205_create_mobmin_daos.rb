class CreateMobminDaos < ActiveRecord::Migration
  def self.up
    create_table :mobmin_daos do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :mobmin_daos
  end
end
