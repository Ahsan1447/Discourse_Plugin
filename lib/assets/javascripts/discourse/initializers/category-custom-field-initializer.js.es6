import { withPluginApi } from 'discourse/lib/plugin-api';

export default {
  name: "category-custom-field-intializer",
  initialize(container) {
    withPluginApi('0.11.2', api => {
      api.registerConnectorClass('category-custom-settings', 'category-custom-field-container', {
        setupComponent(attrs, component) {
          const category = attrs.category;

          if (!category.custom_fields) {
            category.custom_fields = {};
          }

          component.setProperties({
            categoryModel: category
          });
        },

        actions: {
          onChangePostView(value) {
            this.set('categoryModel.custom_fields.post_view', value);
          },
          
          onChangeTabsView(value) {
            this.set('categoryModel.custom_fields.tabs_view', value);
          },
          
          onChangeUserCanCreatePost(value) {
            this.set('categoryModel.custom_fields.user_can_create_post', value);
          },

          onChangeMainPostView(value) {
            this.set('categoryModel.custom_fields.show_main_post', value);
          }
        }
      });
    });
  }
}