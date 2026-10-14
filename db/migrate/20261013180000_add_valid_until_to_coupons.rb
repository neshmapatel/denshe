class AddValidUntilToCoupons < ActiveRecord::Migration[8.1]
  def change
    add_column :coupons, :valid_until, :date
  end
end