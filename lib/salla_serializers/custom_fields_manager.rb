# frozen_string_literal: true

module SallaSerializers
  module CustomFieldsManager
    CUSTOM_FIELDS = {
      'post_view' => { type: :string, choices: ['grid', 'list'], default: 'list' },
      'tabs_view' => { type: :boolean, default: true },
      'user_can_create_post' => { type: :boolean, default: true },
      'show_main_post' => { type: :boolean, default: false }
    }.freeze

    def self.initialize_custom_fields
      CUSTOM_FIELDS.each do |field_name, config|
        # Add getter method with proper boolean conversion and defaults
        add_to_class(:category, field_name.to_sym) do
          value = custom_fields[field_name]
          if config[:type] == :boolean
            # Convert string boolean to actual boolean, with default fallback
            if value.nil?
              config[:default]
            else
              value == "t" || value == true
            end
          else
            # Return default if value is nil
            value.nil? ? config[:default] : value
          end
        end

        # Add setter method - ensure false values are stored as "f"
        add_to_class(:category, "#{field_name}=") do |value|
          if config[:type] == :boolean
            # Always store boolean values as strings, even when false
            # This ensures false values are preserved and not removed
            custom_fields[field_name] = value ? "t" : "f"
          else
            # For non-boolean fields, store the value as-is
            custom_fields[field_name] = value
          end
        end
      end
    end

    def self.setup_category_defaults
      # Set defaults for new categories
      on(:category_created) do |category|
        CUSTOM_FIELDS.each do |field_name, config|
          if category.custom_fields[field_name].nil?
            if config[:type] == :boolean
              category.custom_fields[field_name] = config[:default] ? "t" : "f"
            else
              category.custom_fields[field_name] = config[:default]
            end
            category.save_custom_fields
          end
        end
      end
    end

    def self.setup_preloading_and_serialization
      # Preload all custom fields
      CUSTOM_FIELDS.keys.each do |field_name|
        Site.preloaded_category_custom_fields << field_name
      end

      # Add to serializers
      CUSTOM_FIELDS.keys.each do |field_name|
        add_to_serializer(:site_category, field_name.to_sym) do
          object.send(field_name)
        end
      end
    end
  end
end 