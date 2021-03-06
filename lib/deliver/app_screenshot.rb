require 'fastimage'

module Deliver
  # AppScreenshot represents one screenshots for one specific locale and
  # device type.
  class AppScreenshot
    module ScreenSize
      # iPhone 4
      IOS_35 = "iOS-3.5-in"
      # iPhone 5
      IOS_40 = "iOS-4-in"
      # iPhone 6
      IOS_47 = "iOS-4.7-in"
      # iPhone 6 Plus
      IOS_55 = "iOS-5.5-in"
      # iPad
      IOS_IPAD = "iOS-iPad"
      # Apple Watch
      IOS_APPLE_WATCH = "iOS-Apple-Watch"
      # Mac
      MAC = "Mac"
    end

    # @return [Deliver::ScreenSize] the screen size (device type)
    #  specified at {Deliver::ScreenSize}
    attr_accessor :screen_size

    attr_accessor :path

    attr_accessor :language

    # @param path (String) path to the screenshot file
    # @param path (String) Language of this screenshot (e.g. English)
    # @param screen_size (Deliver::AppScreenshot::ScreenSize) the screen size, which
    #  will automatically be calculated when you don't set it.
    def initialize(path, language, screen_size = nil)
      self.path = path
      self.language = language
      screen_size ||= self.class.calculate_screen_size(path)

      self.screen_size = screen_size

      Helper.log.error "Looks like the screenshot given (#{path}) does not match the requirements of #{screen_size}" unless self.is_valid?
    end

    # The iTC API requires a different notation for the device
    def device_type
      matching = {
        ScreenSize::IOS_35 => "iphone35",
        ScreenSize::IOS_40 => "iphone4",
        ScreenSize::IOS_47 => "iphone6",
        ScreenSize::IOS_55 => "iphone6Plus",
        ScreenSize::IOS_IPAD => "ipad",
        ScreenSize::MAC => "mac",
        ScreenSize::IOS_APPLE_WATCH => "watch"
      }
      return matching[self.screen_size]
    end

    # Nice name
    def formatted_name
      matching = {
        ScreenSize::IOS_35 => "iPhone 4",
        ScreenSize::IOS_40 => "iPhone 5",
        ScreenSize::IOS_47 => "iPhone 6",
        ScreenSize::IOS_55 => "iPhone 6 Plus",
        ScreenSize::IOS_IPAD => "iPad",
        ScreenSize::MAC => "Mac",
        ScreenSize::IOS_APPLE_WATCH => "Watch"
      }
      return matching[self.screen_size]
    end

    # Validates the given screenshots (size and format)
    # rubocop:disable Style/PredicateName
    def is_valid?
      return false unless ["png", "PNG", "jpg", "JPG", "jpeg", "JPEG"].include?(self.path.split(".").last)

      return self.screen_size == self.class.calculate_screen_size(self.path)
    end
    # rubocop:enable Style/PredicateName

    def self.calculate_screen_size(path)
      size = FastImage.size(path)

      raise "Could not find or parse file at path '#{path}'" if size.nil? or size.count == 0

      devices = {
        ScreenSize::IOS_55 => [
          [1080, 1920],
          [1242, 2208]
        ],
        ScreenSize::IOS_47 => [
          [750, 1334]
        ],
        ScreenSize::IOS_40 => [
          [640, 1136],
          [640, 1096],
          [1136, 600] # landscape status bar is smaller
        ],
        ScreenSize::IOS_35 => [
          [640, 960],
          [640, 920],
          [960, 600] # landscape status bar is smaller
        ],
        ScreenSize::IOS_IPAD => [
          [1024, 748],
          [1024, 768],
          [2048, 1496],
          [2048, 1536],
          [768, 1004],
          [768, 1024],
          [1536, 2008],
          [1536, 2048]
        ],
        ScreenSize::MAC => [
          [1280, 800],
          [1440, 900],
          [2880, 1800],
          [2560, 1600]
        ],
        ScreenSize::IOS_APPLE_WATCH => [
          [312, 390]
        ]
      }

      devices.each do |device_type, array|
        array.each do |resolution|
          if (size[0] == resolution[0] and size[1] == resolution[1]) or # portrait
             (size[1] == resolution[0] and size[0] == resolution[1]) # landscape
            return device_type
          end
        end
      end

      raise "Unsupported screen size #{size} for path '#{path}'".red
    end
  end

  ScreenSize = AppScreenshot::ScreenSize
end
