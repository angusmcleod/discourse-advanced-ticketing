import { default as computed } from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Controller.extend({
  @computed('email', 'forwarding')
  forwardDisabled(email, forwarding) {
    return !email || forwarding;
  },

  actions: {
    forward() {
      const model = this.get('model');
      const message = this.get('message');
      const email = this.get('email');

      if (!email) return;

      this.set('forwarding', true);

      ajax('/ticketing/forward', {
        type: 'POST',
        data: {
          post_id: model.postId,
          message,
          email
        }
      }).catch(popupAjaxError).then(result => {
        if (result.sucess) {
          this.set('result', 'check')
        } else {
          this.set('result', 'times')
        }
      }).finally(() => {
        this.set('forwarding', false);
      });
    }
  }
});
