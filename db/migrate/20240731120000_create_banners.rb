class CreateBanners < ActiveRecord::Migration[6.0]
  def change
    create_table :banners do |t|
      t.string :announcement
      t.string :button_text
      t.string :button_link
      t.timestamps
    end
  end
end