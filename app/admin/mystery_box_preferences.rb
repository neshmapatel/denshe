ActiveAdmin.register MysteryBoxPreference do
  menu parent: "Sales", label: "Mystery boxes", priority: 3

  permit_params :order_id, :recipient_type, :jewellery_personality, :style_preference,
                :jewellery_amount, :occasion, :personal_message, :add_gift_note, :gift_note,
                :piece_count_min, :piece_count_max, :box_price, preferred_categories: [],
                preferred_finishes: []

  index do
    id_column
    column :order
    column :recipient_type
    column :style_preference
    column :occasion
    column("Finishes") { |preference| preference.preferred_finishes.join(", ") }
    column("Price") { |preference| "₹#{preference.box_price}" }
    actions
  end

  filter :recipient_type
  filter :style_preference
  filter :occasion

  show do
    attributes_table do
      row :order
      resource.summary_lines.each do |label, value|
        row(label) { value }
      end
      row(:pieces) { |preference| "#{preference.piece_count_min}–#{preference.piece_count_max}" }
      row(:box_price) { |preference| "₹#{preference.box_price}" }
    end
  end
end
