# Gives a model an `images` attachment that is stored as WebP.
#
# Every upload that goes through `images.attach(...)` or `images = ...` is
# compressed first (see ImageCompressor), whichever screen or script it came
# from. The original is kept only when WebP would not be smaller.
module WebpImages
  extend ActiveSupport::Concern

  # Wraps the attachment proxy so `record.images.attach(upload)` compresses.
  module CompressedAttach
    def attach(*attachables)
      super(*ImageCompressor.compress_attachables(attachables))
    end
  end

  # Wraps the writer used by `record.images = [...]` and `update(images: [...])`.
  module CompressedWriter
    def images
      super.tap { |proxy| proxy.extend(CompressedAttach) }
    end

    def images=(attachables)
      super(ImageCompressor.compress_attachables(attachables))
    end
  end

  included do
    has_many_attached :images
    prepend CompressedWriter
  end
end
