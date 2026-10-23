class CreateCuratedGifts < ActiveRecord::Migration[8.1]
  def up
    create_table :curated_gifts do |t|
      t.string :name, null: false
      t.string :product_title, null: false
      t.string :subtitle
      t.string :slug, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.decimal :compare_at_price, precision: 10, scale: 2
      t.decimal :discount_percent, precision: 5, scale: 2, null: false, default: 0
      t.integer :status, null: false, default: 1
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :curated_gifts, :slug, unique: true
    add_index :curated_gifts, :status
    add_index :curated_gifts, :position

    add_reference :order_items, :curated_gift, foreign_key: true, null: true

    CuratedGift.seed_defaults! rescue nil
  end

  def down
    remove_reference :order_items, :curated_gift, foreign_key: true if column_exists?(:order_items, :curated_gift_id)
    drop_table :curated_gifts if table_exists?(:curated_gifts)
  end
end
