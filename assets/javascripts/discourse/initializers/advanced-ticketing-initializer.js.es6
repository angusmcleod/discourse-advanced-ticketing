import { withPluginApi } from 'discourse/lib/plugin-api';
import showModal from 'discourse/lib/show-modal';

export default {
  name: 'advanced-ticketing-initializer',
  initialize(container) {
    const currentUser = container.lookup('current-user:main');
    const siteSettings = container.lookup("site-settings:main");

    withPluginApi('0.8.30', api => {
      api.includePostAttributes('topic');

      api.addPostMenuButton('forward', (attrs, state, siteSettings) => {
        const isPm = attrs.topic.get('archetype') == 'private_message';
        const allowedGroups = attrs.topic.get('details.allowed_groups');
        if (isPm && allowedGroups.length) {
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
          const postNumber = this.attrs.post_number;
          const allowedGroups = this.attrs.topic.get('details.allowed_groups');
          const groupId = allowedGroups[0].id;
          showModal('forward-modal', {
            model: {
              postId,
              postNumber,
              groupId
            }
          });
        }
      });
    });
  }
}
