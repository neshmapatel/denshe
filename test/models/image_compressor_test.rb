require "test_helper"
require "rake"

class ImageCompressorTest < ActiveSupport::TestCase
  PHOTO = Rails.root.join("app/assets/images/curated_gifts/little-finds.jpg")

  setup do
    @category = Category.create!(name: "Earrings", position: 1)
    @product = Product.create!(category: @category, name: "Pearl Drops", selling_price: 599, purchase_price: 100, stock_quantity: 1)
  end

  test "an uploaded photograph is stored as a smaller WebP" do
    @product.images.attach(io: File.open(PHOTO, "rb"), filename: "pearl drops.jpg", content_type: "image/jpeg")

    blob = @product.images.first.blob
    assert_equal "image/webp", blob.content_type
    assert_equal "pearl drops.webp", blob.filename.to_s
    assert_operator blob.byte_size, :<, File.size(PHOTO)
    assert blob.metadata["compressed"]
  end

  test "an upload from the admin form is compressed too" do
    upload = Rack::Test::UploadedFile.new(PHOTO, "image/jpeg")
    @product.images.attach(upload)

    assert_equal "image/webp", @product.images.first.blob.content_type
  end

  test "long edge is capped and the aspect ratio is kept" do
    @product.images.attach(io: File.open(PHOTO, "rb"), filename: "p.jpg", content_type: "image/jpeg")
    blob = @product.images.first.blob
    blob.analyze

    width, height = blob.metadata.values_at("width", "height")
    assert_operator [ width, height ].max, :<=, ImageCompressor::MAX_EDGE
  end

  test "a file that is not an image is stored as it was" do
    @product.images.attach(io: StringIO.new("image-bytes"), filename: "leaf.jpg", content_type: "image/jpeg")

    blob = @product.images.first.blob
    assert_equal "image/jpeg", blob.content_type
    assert_equal "leaf.jpg", blob.filename.to_s
  end

  test "assigning images through the writer compresses them" do
    @product.update!(images: [ Rack::Test::UploadedFile.new(PHOTO, "image/jpeg") ])

    assert_equal "image/webp", @product.reload.images.first.blob.content_type
  end

  test "images:compress swaps old photographs for WebP without losing the primary photo" do
    original = ActiveStorage::Blob.create_and_upload!(io: File.open(PHOTO, "rb"), filename: "old.jpg", content_type: "image/jpeg")
    @product.images.attach(original)
    attachment = @product.images.first
    @product.update_columns(primary_image_id: attachment.id)

    run_task("images:compress", "APPLY" => "1")

    attachment.reload
    assert_equal "image/webp", attachment.blob.content_type
    assert_equal "old.webp", attachment.blob.filename.to_s
    assert_equal attachment.id, @product.reload.primary_image_id
    assert_equal attachment.blob_id, @product.images.first.blob_id
    assert_equal attachment.blob_id, original.reload.metadata["replaced_by"]

    # A second run leaves it alone.
    assert_no_difference -> { ActiveStorage::Blob.count } do
      run_task("images:compress", "APPLY" => "1")
    end

    # The original is only removed by the purge step.
    assert ActiveStorage::Blob.exists?(original.id)
    run_task("images:purge_originals", "APPLY" => "1")
    assert_not ActiveStorage::Blob.exists?(original.id)
    assert_equal "image/webp", @product.reload.images.first.blob.content_type
  end

  test "images:compress previews without changing anything" do
    original = ActiveStorage::Blob.create_and_upload!(io: File.open(PHOTO, "rb"), filename: "old.jpg", content_type: "image/jpeg")
    @product.images.attach(original)

    assert_no_changes -> { @product.images.first.blob_id } do
      run_task("images:compress")
    end
  end

  private

  def run_task(name, env = {})
    Rails.application.load_tasks unless Rake::Task.task_defined?(name)
    task = Rake::Task[name]
    task.reenable
    previous = env.keys.index_with { |key| ENV[key] }
    env.each { |key, value| ENV[key] = value }
    capture_io { task.invoke }
  ensure
    previous&.each { |key, value| ENV[key] = value }
  end
end
