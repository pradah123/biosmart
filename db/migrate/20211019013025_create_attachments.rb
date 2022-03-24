class CreateAttachments < ActiveRecord::Migration[6.1]
  def change
    create_table :attachments do |t|
      t.string :name
      t.text :data
      t.integer :article_id
      t.integer :order

      t.timestamps
    end
  end
end
