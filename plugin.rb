# frozen_string_literal: true

# name: discourse-post-device
# about: Shows the kind of device each post was written on next to its date
# version: 0.1.0
# authors: Sparkloc
# url: https://github.com/moyan78641/discourse-post-device

enabled_site_setting :post_device_enabled

register_asset "stylesheets/post-device.scss"

register_svg_icon "mobile-screen-button"
register_svg_icon "tablet-screen-button"
register_svg_icon "desktop"

require_relative "lib/discourse_post_device/user_agent_parser"

after_initialize do
  add_to_class(:topic_view, :post_device_user_agents) do
    cached = preloaded_post_data(:post_device)
    return cached if cached

    ids = Array(posts).map(&:id)
    stats = PostStat.where(post_id: ids).where.not(writing_device_user_agent: nil)
    agents = ids.index_with(nil)
    agents.merge!(stats.pluck(:post_id, :writing_device_user_agent).to_h)

    set_preloaded_post_data(:post_device, agents)
    agents
  end

  add_to_serializer(:post, :post_device, include_condition: -> { post_device.present? }) do
    return @post_device if defined?(@post_device)

    agents = @topic_view.try(:post_device_user_agents)
    user_agent =
      if agents&.key?(object.id)
        agents[object.id]
      else
        object.post_stat&.writing_device_user_agent
      end

    @post_device = DiscoursePostDevice::UserAgentParser.parse(user_agent)
  rescue StandardError => e
    Rails.logger.warn("[discourse-post-device] post #{object.id}: #{e.message}")
    @post_device = nil
  end
end
