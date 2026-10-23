# Turns product photographs into WebP so the shop sends a fraction of the bytes
# without any visible loss.
#
# Photographs are re-encoded at a high WebP quality and are capped at MAX_EDGE
# pixels on the longest side, which is well above the largest size the shop ever
# displays (1400 x 1867). Colour profiles are converted to sRGB before the
# metadata is stripped, so colours look the same as the original.
#
# Compression never blocks an upload: when a file cannot be processed, or the
# WebP would not be smaller, the original is kept untouched.
class ImageCompressor
  # The longest side, in pixels, that is kept.
  MAX_EDGE = 2400
  # Tried in order. The first result that is smaller than the original wins.
  QUALITIES = [ 85, 75 ].freeze
  # Files that are already WebP are only re-encoded when they are this large.
  RECOMPRESS_WEBP_ABOVE = 500.kilobytes

  CONVERTIBLE_TYPES = %w[image/jpeg image/png image/bmp image/tiff].freeze
  WEBP = "image/webp".freeze

  # +tempfile+ holds the new WebP when +changed+ is true. Close it when done.
  Result = Struct.new(:tempfile, :content_type, :byte_size, :original_byte_size, :changed, keyword_init: true) do
    def changed?
      changed
    end

    def saved_bytes
      original_byte_size - byte_size
    end
  end

  class << self
    # False when neither libvips nor ImageMagick can be loaded.
    def available?
      return @available unless @available.nil?

      @available = begin
        require "image_processing/#{ActiveStorage.variant_processor}"
        true
      rescue LoadError, StandardError
        false
      end
    end

    # Compresses the file at +path+. When the WebP is smaller, the result holds
    # it in a tempfile; otherwise it reports no change. Raises when the file is
    # not a readable image.
    def compress_file(path, content_type:)
      original_size = File.size(path)
      unchanged = Result.new(content_type: content_type, byte_size: original_size,
                             original_byte_size: original_size, changed: false)
      return unchanged unless available? && compressible?(content_type, original_size)

      QUALITIES.each do |quality|
        candidate = encode(path, quality)
        if candidate.size < original_size
          return Result.new(tempfile: candidate, content_type: WEBP, byte_size: candidate.size,
                            original_byte_size: original_size, changed: true)
        end

        candidate.close!
      end

      unchanged
    end

    def compressible?(content_type, byte_size)
      type = content_type.to_s.split(";").first
      return true if CONVERTIBLE_TYPES.include?(type)

      type == WEBP && byte_size > RECOMPRESS_WEBP_ABOVE
    end

    # Takes whatever Active Storage accepts for an attachment and hands back
    # the same thing, swapped for a WebP when that is smaller. Signed ids,
    # blobs, and anything that is not an image pass straight through.
    def compress_attachable(attachable)
      case attachable
      when Hash
        compress_hash(attachable.symbolize_keys)
      when ActiveStorage::Blob, String, nil
        attachable
      else
        attachable.respond_to?(:tempfile) || attachable.respond_to?(:path) ? compress_upload(attachable) : attachable
      end
    rescue StandardError => error
      Rails.logger.warn("Image compression skipped: #{error.class}: #{error.message}")
      attachable
    end

    def compress_attachables(attachables)
      Array(attachables).flatten.map { |attachable| compress_attachable(attachable) }
    end

    def webp_filename(filename)
      "#{File.basename(filename.to_s, '.*').presence || 'photo'}.webp"
    end

    private

    def compress_upload(upload)
      source = upload.respond_to?(:tempfile) ? upload.tempfile : upload
      return upload unless source.respond_to?(:path) && source.path

      filename = upload.try(:original_filename) || File.basename(source.path)
      content_type = upload.try(:content_type).presence || Marcel::MimeType.for(Pathname.new(source.path), name: filename)
      swapped(source.path, filename: filename, content_type: content_type) || upload
    end

    def compress_hash(attachable)
      io = attachable[:io]
      return attachable unless io

      filename = attachable[:filename].to_s
      content_type = attachable[:content_type].to_s
      content_type = Marcel::MimeType.for(io, name: filename) if content_type.blank? || content_type == "application/octet-stream"
      return attachable unless compressible?(content_type, io.try(:size).to_i)

      if io.respond_to?(:path) && io.path
        replacement = swapped(io.path, filename: filename, content_type: content_type)
      else
        staged = Tempfile.new([ "upload", File.extname(filename) ], binmode: true)
        begin
          io.rewind if io.respond_to?(:rewind)
          IO.copy_stream(io, staged)
          staged.flush
          io.rewind if io.respond_to?(:rewind)
          replacement = swapped(staged.path, filename: filename, content_type: content_type)
        ensure
          staged.close!
        end
      end

      replacement ? attachable.merge(replacement) : attachable
    end

    # Attachable for the WebP, or nil when nothing was gained. The "compressed"
    # mark stops images:compress from re-encoding it later.
    def swapped(path, filename:, content_type:)
      result = compress_file(path, content_type: content_type)
      return unless result.changed?

      Rails.logger.info("Image compressed: #{filename} #{result.original_byte_size} -> #{result.byte_size} bytes")
      # Held in memory so the temporary file can go straight away.
      { io: StringIO.new(File.binread(result.tempfile.path)), filename: webp_filename(filename),
        content_type: WEBP, metadata: { "compressed" => true } }
    ensure
      result&.tempfile&.close!
    end

    def encode(path, quality)
      pipeline = ActiveStorage.variant_processor == :mini_magick ? ImageProcessing::MiniMagick : ImageProcessing::Vips
      pipeline = pipeline.source(path).resize_to_limit(MAX_EDGE, MAX_EDGE).convert("webp")

      if ActiveStorage.variant_processor == :mini_magick
        # "!icc,*" drops every profile except the colour profile.
        pipeline.append("+profile", "!icc,*").quality(quality).call
      else
        pipeline.custom { |image| to_srgb(image) }.saver(quality: quality, strip: true).call
      end
    end

    # Phone photographs often carry Display P3. Converting before the profile
    # is stripped keeps their colours instead of dulling them.
    def to_srgb(image)
      return image if image.get_typeof("icc-profile-data").zero?

      image.icc_transform("srgb", embedded: true)
    rescue StandardError
      image
    end
  end
end
