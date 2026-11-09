# frozen_string_literal: true

RSpec.describe "Post device badge" do
  fab!(:topic)
  fab!(:first_post) { Fabricate(:post, topic: topic) }

  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:user_agent) { "SparklocApp/0.8.0 (Flutter; iOS 26.1; phone; iPhone 16 Pro)" }

  before do
    enable_current_plugin
    PostStat.create!(post: first_post, writing_device_user_agent: user_agent)
  end

  it "shows the device icon with the device name in a tooltip" do
    topic_page.visit_topic(topic)

    trigger = find(".topic-post .post-device .fk-d-tooltip__trigger")
    expect(trigger).to have_css(".d-icon-mobile-screen-button")

    trigger.hover
    tooltip = "Posted from iPhone 16 Pro (Sparkloc app)"
    expect(page).to have_css(".fk-d-tooltip__content", text: tooltip)
  end
end
