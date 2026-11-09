# frozen_string_literal: true

RSpec.describe DiscoursePostDevice::UserAgentParser do
  describe ".parse" do
    context "with the Sparkloc app" do
      it "returns the reported model" do
        user_agent = "SparklocApp/0.8.0 (Flutter; iOS 26.1; phone; iPhone 16 Pro)"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "phone", label: "iPhone 16 Pro", app: true)
      end

      it "decodes percent-encoded model names" do
        user_agent = "SparklocApp/0.8.0 (Flutter; Android 15; phone; %E5%8D%8E%E4%B8%BA Mate 60)"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "phone", label: "华为 Mate 60", app: true)
      end

      it "falls back to the device family when no model was shared" do
        user_agent = "SparklocApp/0.8.0 (Flutter; iPadOS 26.1; tablet)"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "tablet", label: "iPad", app: true)
      end

      it "recognizes app versions that only report Flutter" do
        device = described_class.parse("SparklocApp/0.7.0 (Flutter)")

        expect(device).to eq(kind: "phone", label: "Sparkloc App", app: true)
      end

      it "treats unknown device kinds as phones" do
        user_agent = "SparklocApp/0.8.0 (Flutter; Android 15; watch; Galaxy Watch)"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "phone", label: "Galaxy Watch", app: true)
      end

      it "strips markup characters from the model" do
        user_agent = "SparklocApp/0.8.0 (Flutter; Android 15; phone; Pixel 9 <script>)"

        device = described_class.parse(user_agent)

        expect(device[:label]).to eq("Pixel 9 script")
      end

      it "truncates long model names" do
        model = "M" * 60
        user_agent = "SparklocApp/0.8.0 (Flutter; Android 15; phone; #{model})"

        device = described_class.parse(user_agent)

        expect(device[:label].length).to eq(40)
      end
    end

    context "with a browser" do
      it "returns the platform and browser for desktop Chrome" do
        user_agent =
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "desktop", label: "Windows · Chrome")
      end

      it "returns the platform and browser for iPhone Safari" do
        user_agent =
          "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "phone", label: "iPhone · Safari")
      end

      it "treats Android browsers without the Mobile token as tablets" do
        user_agent =
          "Mozilla/5.0 (Linux; Android 14; SM-X710) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "tablet", label: "Android · Chrome")
      end

      it "names in-app browsers before the engine they embed" do
        user_agent =
          "Mozilla/5.0 (Linux; Android 14; V2309A Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/116.0.0.0 Mobile Safari/537.36 MicroMessenger/8.0.47.2560(0x28002F30) WeChat/arm64 Weixin NetType/WIFI Language/zh_CN ABI/arm64"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "phone", label: "Android · WeChat")
      end

      it "recognizes HarmonyOS" do
        user_agent =
          "Mozilla/5.0 (Phone; OpenHarmony 5.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 ArkWeb/4.1.6.1 Mobile HuaweiBrowser/5.0.4.300"

        device = described_class.parse(user_agent)

        expect(device).to eq(kind: "phone", label: "HarmonyOS · Huawei Browser")
      end
    end

    context "without a recognizable user agent" do
      it "returns nil for blank values" do
        expect(described_class.parse(nil)).to be_nil
        expect(described_class.parse("")).to be_nil
      end

      it "returns nil for unknown clients" do
        expect(described_class.parse("curl/8.5.0")).to be_nil
      end
    end
  end
end
