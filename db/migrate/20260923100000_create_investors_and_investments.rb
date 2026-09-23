class CreateInvestorsAndInvestments < ActiveRecord::Migration[8.1]
  def change
    create_table :investors do |t|
      t.string :name, null: false
      t.string :email
      t.references :admin_user, foreign_key: true
      t.text :notes
      t.timestamps
    end
    add_index :investors, :name, unique: true

    create_table :investments do |t|
      t.references :investor, null: false, foreign_key: true
      t.references :purchase, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :kind, null: false, default: 0
      t.date :invested_on
      t.text :notes
      t.timestamps
    end

    add_reference :purchases, :funded_by, foreign_key: { to_table: :investors }
  end
end
