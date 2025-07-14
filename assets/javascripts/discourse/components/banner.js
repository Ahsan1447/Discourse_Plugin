import Component from '@ember/component';
import { computed } from '@ember/object';
import { inject as service } from '@ember/service';

export default Component.extend({
  router: service(),
  banner: null,

  init() {
    this._super(...arguments);
    this.loadBanner();
  },

  loadBanner() {
    fetch('/salla/banner')
      .then(response => response.json())
      .then(banner => {
        this.set('banner', banner);
      });
  }
});