module Admin
  class ProductsController < Admin::ApplicationController
    def find_resource(param)
      find_resource_by_slug_or_id(Product, param)
    end

    def scoped_resource
      resource_class.with_attached_images
    end

    def create
      permitted = resource_params
      resource = new_resource(permitted)
      authorize_resource(resource)

      unless validate_stashed_product_images(resource)
        return render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource)
        }, status: :unprocessable_entity
      end

      if resource.save
        attach_stashed_product_images(resource)
        redirect_to(
          after_resource_created_path(resource),
          notice: translate_with_resource("create.success")
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource)
        }, status: :unprocessable_entity
      end
    end

    def update
      permitted = resource_params

      unless validate_stashed_product_images(requested_resource)
        return render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }, status: :unprocessable_entity
      end

      if requested_resource.update(permitted)
        attach_stashed_product_images(requested_resource)
        redirect_to(
          after_resource_updated_path(requested_resource),
          notice: translate_with_resource("update.success"),
          status: :see_other
        )
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }, status: :unprocessable_entity
      end
    end

    private

    def resource_params
      permitted = super
      stash_permitted_image_uploads!(permitted)
      permitted
    end

    def stash_permitted_image_uploads!(permitted)
      @stashed_product_images = nil
      return permitted unless permitted.is_a?(ActionController::Parameters)

      return permitted unless permitted.key?(:images)

      raw = permitted.delete(:images)
      files = raw.present? ? extract_multipart_uploads(raw) : []
      @stashed_product_images = files.presence
      permitted
    end

    def extract_multipart_uploads(raw)
      list = raw.is_a?(Array) ? raw : Array.wrap(raw)
      list.flatten.compact_blank.select do |f|
        f.respond_to?(:original_filename) && f.respond_to?(:read)
      end
    end

    def validate_stashed_product_images(resource)
      uploads = @stashed_product_images
      return true if uploads.blank?

      uploads.each do |file|
        type = file.content_type.to_s
        unless Product::ALLOWED_IMAGE_TYPES.include?(type)
          resource.errors.add(:images, :invalid_type)
          return false
        end
        if file.size > Product::MAX_IMAGE_SIZE
          resource.errors.add(:images, :too_large)
          return false
        end
      end
      true
    end

    def attach_stashed_product_images(record)
      uploads = @stashed_product_images
      @stashed_product_images = nil
      return if uploads.blank?

      uploads.each { |file| record.images.attach(file) }
    end
  end
end
