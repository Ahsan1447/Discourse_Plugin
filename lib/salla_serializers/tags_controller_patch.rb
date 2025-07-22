module SallaSerializers
  module TagsControllerPatch
    def build_topic_list_options
      options = super

      if params[:tag_names].present?
        options[:tags] = params[:tag_names]
        options[:match_all_tags] ||= false
      end

      options
    end
  end
end
