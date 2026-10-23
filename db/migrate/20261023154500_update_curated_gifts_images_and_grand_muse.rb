class UpdateCuratedGiftsImagesAndGrandMuse < ActiveRecord::Migration[8.1]
  def up
    CuratedGift.seed_defaults!(force_reimage: true)
    CuratedGift.where(slug: CuratedGift::DEFAULTS.map { |d| d[:slug] }).update_all(status: 1)
  rescue StandardError => e
    Rails.logger.warn("UpdateCuratedGiftsImagesAndGrandMuse migration notice: #{e.message}")
  end

  def down
    # No-op: keep curated gifts intact on rollback
  end
end
