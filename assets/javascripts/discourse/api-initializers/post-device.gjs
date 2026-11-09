import Component from "@glimmer/component";
import DTooltip from "discourse/float-kit/components/d-tooltip";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

const ICONS = {
  phone: "mobile-screen-button",
  tablet: "tablet-screen-button",
  desktop: "desktop",
};

class PostDevice extends Component {
  get device() {
    return this.args.post?.post_device;
  }

  get icon() {
    return ICONS[this.device.kind] ?? ICONS.phone;
  }

  get deviceName() {
    const { label, app } = this.device;
    if (!app) {
      return label;
    }
    return i18n("discourse_post_device.app", { device: label });
  }

  get tooltip() {
    const device = this.deviceName;
    if (this.args.post.post_number === 1) {
      return i18n("discourse_post_device.posted", { device });
    }
    return i18n("discourse_post_device.replied", { device });
  }

  <template>
    {{#if this.device.label}}
      <div class="post-info post-device">
        <DTooltip
          aria-label={{this.tooltip}}
          @content={{this.tooltip}}
          @icon={{this.icon}}
          @identifier="post-device"
        />
      </div>
    {{/if}}
  </template>
}

function addDeviceInfo({ value: dag, context: { metaDataInfoKeys } }) {
  dag.add("post-device", PostDevice, { before: metaDataInfoKeys.DATE });
}

export default apiInitializer((api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.post_device_enabled) {
    return;
  }

  api.addTrackedPostProperties("post_device");
  api.registerValueTransformer("post-meta-data-infos", addDeviceInfo);
});
