import { default as computed } from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Controller.extend({
  resetProperties() {
    this.setProperties({
      forwarding: false,
      email: '',
      message: '',
      result: '',
      includePrior: null
    });
  },

  @computed('model.excerpt')
  title(excerpt) {
    return I18n.t('advanced_ticketing.forward.modal.title', { excerpt });
  },

  @computed('email', 'forwarding')
  forwardDisabled(email, forwarding) {
    return !email || forwarding;
  },

  @computed('model.postNumber')
  showIncludePrior(postNumber) {
    return postNumber > 1;
  },

  @computed('result')
  resultIcon(result) {
    return result == 'success' ? 'check' : 'times';
  },

  @computed('result')
  resultTextKey(result) {
    return `advanced_ticketing.forward.modal.${result}`;
  },

  actions: {
    forward() {
      const model = this.get('model');
      const message = this.get('message');
      const email = this.get('email');
      const includePrior = this.get('includePrior');

      if (!email) return;

      this.set('forwarding', true);

      ajax('/ticketing/forward', {
        type: 'POST',
        data: {
          post_id: model.postId,
          group_id: model.groupId,
          message,
          email,
          include_prior: includePrior
        }
      }).catch(popupAjaxError).then(result => {
        if (result.success) {
          this.set('result', 'success')
        } else {
          this.set('result', 'fail')
        }
      }).finally(() => {
        this.setProperties({
          forwarding: false,
          email: '',
          message: '',
          includePrior: null
        });
      });
    }
  }
});
