import { withPluginApi } from 'discourse/lib/plugin-api';
import showModal from 'discourse/lib/show-modal';

export default {
  name: 'advanced-ticketing-initializer',
  initialize(container) {
    const currentUser = container.lookup('current-user:main');
    const siteSettings = container.lookup("site-settings:main");

    withPluginApi('0.8.30', api => {
      api.addPostMenuButton('forward', (attrs, state, siteSettings) => {
        if (attrs.allowedGroups /*&& attrs.via_email*/) {
          return {
            action: 'forward',
            icon: 'share',
            className: 'forward',
            title: 'advanced_ticketing.forward.title',
            position: 'first'  // can be `first`, `last` or `second-last-hidden`
          };
        } else {
          return null;
        }
      });

      api.reopenWidget('post-menu', {
        forward() {
          const postId = this.attrs.id;
          showModal('forward-modal', { model: { postId } });
        }
      });
    });
  }
}
