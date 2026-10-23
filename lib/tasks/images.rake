# Compresses photographs that were uploaded before WebP compression existed,
# straight on the server, with no re-upload.
#
#   bin/rails images:compress                          # preview only, changes nothing
#   APPLY=1 bin/rails images:compress                  # compress and swap them in
#   bin/rails images:warm_variants                     # pre-build the shop's image sizes
#   APPLY=1 bin/rails images:purge_originals           # delete the replaced originals
#
# Each photograph keeps its place: the attachment (and therefore the primary
# photo and the gallery order) stays the same and simply points at the new
# WebP file. The original is kept until `images:purge_originals`, so a bad
# result can be rolled back. Re-running is safe; finished photographs are skipped.
#
# Optional: LIMIT=20 to try a handful first, PURGE_ORIGINALS=1 to delete each
# original straight after it has been replaced.
namespace :images do
  desc "Compress existing images to WebP (preview unless APPLY=1)"
  task compress: :environment do
    abort "Image compression is unavailable: neither libvips nor ImageMagick could be loaded." unless ImageCompressor.available?

    apply = ENV["APPLY"] == "1"
    purge = ENV["PURGE_ORIGINALS"] == "1"
    limit = ENV["LIMIT"].presence&.to_i

    blobs = ActiveStorage::Blob.where("content_type LIKE 'image/%'")
                               .where(id: ActiveStorage::Attachment.select(:blob_id))
                               .order(:id)
    totals = Hash.new(0)

    puts apply ? "Compressing images (changes will be saved)." : "Preview only. Nothing is changed. Add APPLY=1 to save."

    blobs.find_each do |blob|
      break if limit && totals[:converted] >= limit

      totals[:seen] += 1
      metadata = blob.metadata
      next totals[:skipped] += 1 if metadata.key?("compressed") || metadata.key?("replaced_by")
      next totals[:skipped] += 1 unless ImageCompressor.compressible?(blob.content_type, blob.byte_size)

      begin
        result = blob.open { |file| ImageCompressor.compress_file(file.path, content_type: blob.content_type) }
      rescue StandardError => error
        totals[:failed] += 1
        puts "  FAILED blob #{blob.id} (#{blob.filename}): #{error.class}: #{error.message}"
        next
      end

      unless result.changed?
        blob.update!(metadata: metadata.merge("compressed" => false)) if apply
        totals[:unchanged] += 1
        next
      end

      begin
        if apply
          replacement = ActiveStorage::Blob.create_and_upload!(
            io: File.open(result.tempfile.path, "rb"),
            filename: ImageCompressor.webp_filename(blob.filename.to_s),
            content_type: ImageCompressor::WEBP,
            metadata: { "compressed" => true },
            identify: false
          )
          replacement.analyze

          ActiveStorage::Blob.transaction do
            ActiveStorage::Attachment.where(blob_id: blob.id).find_each do |attachment|
              attachment.update!(blob: replacement)
              attachment.record&.touch
            end
            blob.update!(metadata: blob.metadata.merge("replaced_by" => replacement.id))
          end
          blob.purge if purge
        end

        totals[:converted] += 1
        totals[:before] += result.original_byte_size
        totals[:after] += result.byte_size
        puts format("  blob %-6d %-40s %8.0f KB -> %6.0f KB", blob.id, blob.filename.to_s.truncate(40),
                    result.original_byte_size / 1024.0, result.byte_size / 1024.0)
      rescue StandardError => error
        totals[:failed] += 1
        puts "  FAILED blob #{blob.id} (#{blob.filename}): #{error.class}: #{error.message}"
      ensure
        result.tempfile&.close!
      end
    end

    saved = totals[:before] - totals[:after]
    puts
    puts "Images checked:      #{totals[:seen]}"
    puts "Compressed:          #{totals[:converted]}"
    puts "Already fine:        #{totals[:skipped] + totals[:unchanged]}"
    puts "Failed:              #{totals[:failed]}"
    puts format("Size before/after: %.1f MB -> %.1f MB (saves %.1f MB, %d%%)",
                totals[:before] / 1.megabyte.to_f, totals[:after] / 1.megabyte.to_f, saved / 1.megabyte.to_f,
                totals[:before].zero? ? 0 : (saved * 100.0 / totals[:before]).round)
    puts "Originals are kept. Run APPLY=1 bin/rails images:purge_originals once the shop looks right." if apply && !purge && totals[:converted].positive?
  end

  desc "Pre-build the WebP sizes the shop uses so the first visitor does not wait"
  task warm_variants: :environment do
    helper = Class.new { include StorefrontHelper }.new
    count = 0

    ActiveStorage::Attachment.where(record_type: %w[Product CuratedGift], name: "images").includes(:blob).find_each do |attachment|
      next unless attachment.blob.image?

      StorefrontHelper::IMAGE_SIZES.each_key { |size| helper.piece_image_source(attachment, size).try(:processed) }
      helper.catalogue_image_source(attachment).try(:processed)
      count += 1
      puts "  warmed #{count} images" if (count % 25).zero?
    rescue StandardError => error
      puts "  FAILED attachment #{attachment.id}: #{error.class}: #{error.message}"
    end

    puts "Warmed #{count} images."
  end

  desc "Delete originals that images:compress replaced (preview unless APPLY=1)"
  task purge_originals: :environment do
    apply = ENV["APPLY"] == "1"
    bytes = 0
    count = 0

    ActiveStorage::Blob.where("metadata LIKE ?", '%"replaced_by"%').find_each do |blob|
      next if blob.attachments.exists?

      bytes += blob.byte_size
      count += 1
      blob.purge if apply
    end

    puts "#{apply ? 'Deleted' : 'Would delete'} #{count} originals (#{(bytes / 1.megabyte.to_f).round(1)} MB)."
    puts "Add APPLY=1 to delete them." unless apply
  end
end
