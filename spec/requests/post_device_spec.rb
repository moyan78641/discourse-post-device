# frozen_string_literal: true

RSpec.describe "Post device" do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  fab!(:first_post) { Fabricate(:post, topic: topic, user: user) }

  let(:app_user_agent) { "SparklocApp/0.8.0 (Flutter; iOS 26.1; phone; iPhone 16 Pro)" }

  before { enable_current_plugin }

  describe "GET /t/:id.json" do
    it "includes the device parsed from the stored user agent" do
      PostStat.create!(post: first_post, writing_device_user_agent: app_user_agent)

      get "/t/#{topic.id}.json"

      expect(response).to have_http_status(:ok)
      device = response.parsed_body.dig("post_stream", "posts", 0, "post_device")
      expect(device).to eq("kind" => "phone", "label" => "iPhone 16 Pro", "app" => true)
    end

    it "omits the device when no user agent was stored" do
      get "/t/#{topic.id}.json"

      post_json = response.parsed_body.dig("post_stream", "posts", 0)
      expect(post_json).not_to have_key("post_device")
    end

    it "omits the device when the plugin is disabled" do
      PostStat.create!(post: first_post, writing_device_user_agent: app_user_agent)
      SiteSetting.post_device_enabled = false

      get "/t/#{topic.id}.json"

      post_json = response.parsed_body.dig("post_stream", "posts", 0)
      expect(post_json).not_to have_key("post_device")
    end
  end

  describe "GET /posts/:id.json" do
    it "includes the device for a single post" do
      user_agent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
      PostStat.create!(post: first_post, writing_device_user_agent: user_agent)

      get "/posts/#{first_post.id}.json"

      expect(response).to have_http_status(:ok)
      device = response.parsed_body["post_device"]
      expect(device).to eq("kind" => "desktop", "label" => "Windows · Chrome")
    end
  end

  describe "POST /posts.json" do
    before do
      SiteSetting.fast_typing_threshold = "disabled"
      PostCreator.track_post_stats = true
      sign_in(user)
    end

    after { PostCreator.track_post_stats = false }

    it "stores the app user agent and returns the device" do
      post_params = { raw: "Replying from the Sparkloc app", topic_id: topic.id }
      post "/posts.json", params: post_params, headers: { "HTTP_USER_AGENT" => app_user_agent }

      expect(response).to have_http_status(:ok)
      device = response.parsed_body["post_device"]
      expect(device).to eq("kind" => "phone", "label" => "iPhone 16 Pro", "app" => true)
    end
  end
end
