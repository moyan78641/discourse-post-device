# frozen_string_literal: true

module ::DiscoursePostDevice
  module UserAgentParser
    APP_PATTERN = %r{\ASparklocApp/\S+ \(Flutter([^)]*)\)}
    KINDS = %w[phone tablet desktop].freeze
    MAX_LABEL = 40

    BROWSERS = [
      [%r{SparklocApp/}, "Sparkloc App"],
      [/DiscourseHub/, "DiscourseHub"],
      [/MicroMessenger/, "WeChat"],
      [/QQBrowser/, "QQ Browser"],
      [/UCBrowser/, "UC Browser"],
      [/Quark/, "Quark"],
      [/MiuiBrowser/, "Mi Browser"],
      [/HuaweiBrowser/, "Huawei Browser"],
      [/SamsungBrowser/, "Samsung Internet"],
      [%r{Edg(?:e|A|iOS)?/}, "Edge"],
      [%r{OPR/|Opera}, "Opera"],
      [%r{Firefox/|FxiOS/}, "Firefox"],
      [%r{Chrome/|CriOS/}, "Chrome"],
      [%r{Safari/}, "Safari"],
    ].freeze

    class << self
      def parse(user_agent)
        return if user_agent.blank?

        match = APP_PATTERN.match(user_agent)
        match ? parse_app(match[1]) : parse_browser(user_agent)
      end

      private

      def parse_app(details)
        os, kind, model = details.split(";").drop(1).map(&:strip)
        kind = "phone" if KINDS.exclude?(kind)
        label = clean(decode(model)) || app_fallback(os, kind)
        { kind: kind, label: label, app: true }
      end

      def app_fallback(os, kind)
        case os
        when /\Ai(?:Pad)?OS\b/
          kind == "tablet" ? "iPad" : "iPhone"
        when /\AmacOS\b/
          "Mac"
        when /\AAndroid\b/
          "Android"
        when /\AHarmonyOS\b/
          "HarmonyOS"
        else
          "Sparkloc App"
        end
      end

      def decode(text)
        return if text.blank?

        bytes = text.b.gsub(/%(\h\h)/) { Regexp.last_match(1).hex.chr }
        bytes.force_encoding(Encoding::UTF_8).scrub("")
      end

      def clean(text)
        return if text.blank?

        cleaned = text.gsub(/[^[:alnum:] ()+\-._,'&]/, " ").squeeze(" ").strip
        cleaned[0, MAX_LABEL].rstrip.presence
      end

      def parse_browser(user_agent)
        os, kind = platform(user_agent)
        return unless os

        browser = BROWSERS.find { |pattern, _| pattern.match?(user_agent) }&.last
        { kind: kind, label: browser ? "#{os} · #{browser}" : os }
      end

      def platform(user_agent)
        case user_agent
        when /HarmonyOS|OpenHarmony/
          ["HarmonyOS", harmony_kind(user_agent)]
        when /iPad/
          %w[iPad tablet]
        when /iPhone|iPod/
          %w[iPhone phone]
        when /Android/
          ["Android", user_agent.include?("Mobile") ? "phone" : "tablet"]
        when /Windows/
          %w[Windows desktop]
        when /CrOS/
          %w[ChromeOS desktop]
        when /Macintosh|Mac OS X/
          %w[Mac desktop]
        when /Linux/
          %w[Linux desktop]
        end
      end

      def harmony_kind(user_agent)
        if user_agent.include?("Tablet")
          "tablet"
        elsif user_agent.include?("(PC;")
          "desktop"
        elsif user_agent.include?("Android") && !user_agent.include?("Mobile")
          "tablet"
        else
          "phone"
        end
      end
    end
  end
end
