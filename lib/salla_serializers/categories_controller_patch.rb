# frozen_string_literal: true

module SallaSerializers
  module CategoriesControllerPatch
    def self.included(base)
      base.class_eval do
        def update
          guardian.ensure_can_edit!(@category)

          json_result(@category, serializer: CategorySerializer) do |cat|
            old_category_params = category_params.dup

            cat.move_to(category_params[:position].to_i) if category_params[:position]
            category_params.delete(:position)

            old_custom_fields = cat.custom_fields.dup
            if category_params[:custom_fields]
              category_params[:custom_fields].each do |key, value|
                # Allow false values for our custom fields
                if SallaSerializers::CustomFieldsManager::CUSTOM_FIELDS.key?(key)
                  cat.custom_fields[key] = value
                else
                  # Use original logic for other fields
                  if value.present?
                    cat.custom_fields[key] = value
                  else
                    cat.custom_fields.delete(key)
                  end
                end
              end
            end
            category_params.delete(:custom_fields)

            # properly null the value so the database constraint doesn't catch us
            category_params[:email_in] = nil if category_params[:email_in]&.blank?
            category_params[:minimum_required_tags] = 0 if category_params[:minimum_required_tags]&.blank?

            old_permissions = cat.permissions_params
            old_permissions = { "everyone" => 1 } if old_permissions.empty?

            if result = cat.update(category_params)
              Scheduler::Defer.later "Log staff action change category settings" do
                @staff_action_logger.log_category_settings_change(
                  @category,
                  old_category_params,
                  old_permissions: old_permissions,
                  old_custom_fields: old_custom_fields,
                )
              end
            end

            DiscourseEvent.trigger(:category_updated, cat) if result

            result
          end
        end
      end
    end
  end
end 