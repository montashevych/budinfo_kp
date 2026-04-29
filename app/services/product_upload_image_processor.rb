# frozen_string_literal: true

# Shrinks admin uploads to fit inside the pixel box and re-encodes as JPEG so stored size stays
# under Product::MAX_STORED_IMAGE_BYTES (see successive quality / dimension steps).
# If libvips is unavailable (e.g. some local dev setups), the original file is returned.
class ProductUploadImageProcessor
  RESIZE_STEPS = [
    [ 1920, 1080 ],
    [ 1600, 900 ],
    [ 1280, 720 ],
    [ 1024, 576 ],
    [ 800, 450 ]
  ].freeze

  JPEG_QUALITIES = [ 88, 80, 72, 64, 56, 48, 40 ].freeze

  class << self
    def call(uploaded_file)
      path = tempfile_path(uploaded_file)
      encoded = encode_under_byte_limit(path, uploaded_file)
      return encoded if encoded

      Rails.logger.warn(
        "[ProductUploadImageProcessor] could not compress under #{Product::MAX_STORED_IMAGE_BYTES} bytes — using original file"
      )
      rewind_upload(uploaded_file)
      [
        uploaded_file.tempfile,
        uploaded_file.original_filename.presence || "image.jpg",
        uploaded_file.content_type.presence || "image/jpeg"
      ]
    rescue LoadError, NameError, StandardError => e
      Rails.logger.warn("[ProductUploadImageProcessor] #{e.class}: #{e.message} — using original file")
      rewind_upload(uploaded_file)
      [
        uploaded_file.tempfile,
        uploaded_file.original_filename.presence || "image.jpg",
        uploaded_file.content_type.presence || "image/jpeg"
      ]
    end

    private

    def encode_under_byte_limit(path, uploaded_file)
      base = File.basename(uploaded_file.original_filename.to_s, ".*")
      filename = "#{base.presence || 'image'}.jpg"
      limit = Product::MAX_STORED_IMAGE_BYTES

      RESIZE_STEPS.each do |dims|
        JPEG_QUALITIES.each do |quality|
          out = ImageProcessing::Vips
            .source(path)
            .resize_to_limit(*dims)
            .convert("jpeg")
            .saver(quality: quality)
            .call
          out.rewind if out.respond_to?(:rewind)
          bytes = tempfile_bytesize(out)
          if bytes <= limit
            return [ out, filename, "image/jpeg" ]
          end

          dispose_tempfile(out)
        end
      end

      nil
    end

    def tempfile_bytesize(io)
      File.size(io.path)
    end

    def dispose_tempfile(out)
      out.close if out.respond_to?(:close) && !out.closed?
      out.unlink if out.respond_to?(:unlink)
    rescue StandardError
      nil
    end

    def tempfile_path(uploaded_file)
      if uploaded_file.respond_to?(:tempfile) && uploaded_file.tempfile
        uploaded_file.tempfile.path
      elsif uploaded_file.respond_to?(:path)
        uploaded_file.path
      else
        raise ArgumentError, "Unsupported upload type"
      end
    end

    def rewind_upload(uploaded_file)
      uploaded_file.tempfile&.rewind
    end
  end
end
