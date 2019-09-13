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
      includePrior: null,
      hideResponses: true
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
    return result === 'success' ? 'check' : 'times';
  },

  @computed('result')
  resultTextKey(result) {
    return `advanced_ticketing.forward.modal.${result}`;
  },

  actions: {
    forward() {
      const {
        model,
        message,
        email,
        includePrior,
        hideResponses
      } = this.getProperties(
        'model',
        'message',
        'email',
        'includePrior',
        'hideResponses'
      );

      if (!email) return;

      let data = {
        post_id: model.postId,
        group_id: model.groupId,
        message,
        email
      };

      if (includePrior) data['include_prior'] = includePrior;
      if (hideResponses) data['hide_responses'] = hideResponses;

      this.set('forwarding', true);

      ajax('/ticketing/forward', {
        type: 'POST',
        data
      }).catch(popupAjaxError).then(result => {
        this.set('result', result.success ? 'success' : 'fail');
      }).finally(() => {
        this.setProperties({
          forwarding: false,
          email: '',
          message: '',
          includePrior: null,
          hideResponses: true
        });
      });
    }
  }
});
