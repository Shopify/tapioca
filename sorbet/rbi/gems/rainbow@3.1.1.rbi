# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rainbow` gem.
# Please instead update this file by running `bin/tapioca gem rainbow`.


class Object < ::BasicObject
  include ::Kernel
  include ::PP::ObjectMixin

  private

  # source://rainbow//lib/rainbow/global.rb#23
  def Rainbow(string); end
end

# source://rainbow//lib/rainbow/string_utils.rb#3
module Rainbow
  class << self
    # source://rainbow//lib/rainbow/global.rb#10
    def enabled; end

    # source://rainbow//lib/rainbow/global.rb#14
    def enabled=(value); end

    # source://rainbow//lib/rainbow/global.rb#6
    def global; end

    # source://rainbow//lib/rainbow.rb#6
    def new; end

    # source://rainbow//lib/rainbow/global.rb#18
    def uncolor(string); end
  end
end

# source://rainbow//lib/rainbow/color.rb#4
class Rainbow::Color
  # Returns the value of attribute ground.
  #
  # source://rainbow//lib/rainbow/color.rb#5
  def ground; end

  class << self
    # source://rainbow//lib/rainbow/color.rb#7
    def build(ground, values); end

    # source://rainbow//lib/rainbow/color.rb#40
    def parse_hex_color(hex); end
  end
end

# source://rainbow//lib/rainbow/color.rb#54
class Rainbow::Color::Indexed < ::Rainbow::Color
  # @return [Indexed] a new instance of Indexed
  #
  # source://rainbow//lib/rainbow/color.rb#57
  def initialize(ground, num); end

  # source://rainbow//lib/rainbow/color.rb#62
  def codes; end

  # Returns the value of attribute num.
  #
  # source://rainbow//lib/rainbow/color.rb#55
  def num; end
end

# source://rainbow//lib/rainbow/color.rb#69
class Rainbow::Color::Named < ::Rainbow::Color::Indexed
  # @return [Named] a new instance of Named
  #
  # source://rainbow//lib/rainbow/color.rb#90
  def initialize(ground, name); end

  class << self
    # source://rainbow//lib/rainbow/color.rb#82
    def color_names; end

    # source://rainbow//lib/rainbow/color.rb#86
    def valid_names; end
  end
end

# source://rainbow//lib/rainbow/color.rb#70
Rainbow::Color::Named::NAMES = T.let(T.unsafe(nil), Hash)

# source://rainbow//lib/rainbow/color.rb#100
class Rainbow::Color::RGB < ::Rainbow::Color::Indexed
  # @return [RGB] a new instance of RGB
  #
  # source://rainbow//lib/rainbow/color.rb#107
  def initialize(ground, *values); end

  # Returns the value of attribute b.
  #
  # source://rainbow//lib/rainbow/color.rb#101
  def b; end

  # source://rainbow//lib/rainbow/color.rb#116
  def codes; end

  # Returns the value of attribute g.
  #
  # source://rainbow//lib/rainbow/color.rb#101
  def g; end

  # Returns the value of attribute r.
  #
  # source://rainbow//lib/rainbow/color.rb#101
  def r; end

  private

  # source://rainbow//lib/rainbow/color.rb#122
  def code_from_rgb; end

  class << self
    # source://rainbow//lib/rainbow/color.rb#103
    def to_ansi_domain(value); end
  end
end

# source://rainbow//lib/rainbow/color.rb#129
class Rainbow::Color::X11Named < ::Rainbow::Color::RGB
  include ::Rainbow::X11ColorNames

  # @return [X11Named] a new instance of X11Named
  #
  # source://rainbow//lib/rainbow/color.rb#140
  def initialize(ground, name); end

  class << self
    # source://rainbow//lib/rainbow/color.rb#132
    def color_names; end

    # source://rainbow//lib/rainbow/color.rb#136
    def valid_names; end
  end
end

# source://rainbow//lib/rainbow/null_presenter.rb#4
class Rainbow::NullPresenter < ::String
  # source://rainbow//lib/rainbow/null_presenter.rb#9
  def background(*_values); end

  # source://rainbow//lib/rainbow/null_presenter.rb#95
  def bg(*_values); end

  # source://rainbow//lib/rainbow/null_presenter.rb#49
  def black; end

  # source://rainbow//lib/rainbow/null_presenter.rb#33
  def blink; end

  # source://rainbow//lib/rainbow/null_presenter.rb#65
  def blue; end

  # source://rainbow//lib/rainbow/null_presenter.rb#96
  def bold; end

  # source://rainbow//lib/rainbow/null_presenter.rb#17
  def bright; end

  # source://rainbow//lib/rainbow/null_presenter.rb#5
  def color(*_values); end

  # source://rainbow//lib/rainbow/null_presenter.rb#45
  def cross_out; end

  # source://rainbow//lib/rainbow/null_presenter.rb#73
  def cyan; end

  # source://rainbow//lib/rainbow/null_presenter.rb#97
  def dark; end

  # source://rainbow//lib/rainbow/null_presenter.rb#21
  def faint; end

  # source://rainbow//lib/rainbow/null_presenter.rb#94
  def fg(*_values); end

  # source://rainbow//lib/rainbow/null_presenter.rb#93
  def foreground(*_values); end

  # source://rainbow//lib/rainbow/null_presenter.rb#57
  def green; end

  # source://rainbow//lib/rainbow/null_presenter.rb#41
  def hide; end

  # source://rainbow//lib/rainbow/null_presenter.rb#37
  def inverse; end

  # source://rainbow//lib/rainbow/null_presenter.rb#25
  def italic; end

  # source://rainbow//lib/rainbow/null_presenter.rb#69
  def magenta; end

  # source://rainbow//lib/rainbow/null_presenter.rb#81
  def method_missing(method_name, *args); end

  # source://rainbow//lib/rainbow/null_presenter.rb#53
  def red; end

  # source://rainbow//lib/rainbow/null_presenter.rb#13
  def reset; end

  # source://rainbow//lib/rainbow/null_presenter.rb#98
  def strike; end

  # source://rainbow//lib/rainbow/null_presenter.rb#29
  def underline; end

  # source://rainbow//lib/rainbow/null_presenter.rb#77
  def white; end

  # source://rainbow//lib/rainbow/null_presenter.rb#61
  def yellow; end

  private

  # @return [Boolean]
  #
  # source://rainbow//lib/rainbow/null_presenter.rb#89
  def respond_to_missing?(method_name, *args); end
end

# source://rainbow//lib/rainbow/presenter.rb#8
class Rainbow::Presenter < ::String
  # Sets background color of this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#30
  def background(*values); end

  # Sets background color of this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#34
  def bg(*values); end

  # source://rainbow//lib/rainbow/presenter.rb#92
  def black; end

  # Turns on blinking attribute for this text (not well supported by terminal
  # emulators).
  #
  # source://rainbow//lib/rainbow/presenter.rb#72
  def blink; end

  # source://rainbow//lib/rainbow/presenter.rb#108
  def blue; end

  # Turns on bright/bold for this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#49
  def bold; end

  # Turns on bright/bold for this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#45
  def bright; end

  # Sets color of this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#22
  def color(*values); end

  # source://rainbow//lib/rainbow/presenter.rb#86
  def cross_out; end

  # source://rainbow//lib/rainbow/presenter.rb#116
  def cyan; end

  # Turns on faint/dark for this text (not well supported by terminal
  # emulators).
  #
  # source://rainbow//lib/rainbow/presenter.rb#57
  def dark; end

  # Turns on faint/dark for this text (not well supported by terminal
  # emulators).
  #
  # source://rainbow//lib/rainbow/presenter.rb#53
  def faint; end

  # Sets color of this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#27
  def fg(*values); end

  # Sets color of this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#26
  def foreground(*values); end

  # source://rainbow//lib/rainbow/presenter.rb#100
  def green; end

  # Hides this text (set its color to the same as background).
  #
  # source://rainbow//lib/rainbow/presenter.rb#82
  def hide; end

  # Inverses current foreground/background colors.
  #
  # source://rainbow//lib/rainbow/presenter.rb#77
  def inverse; end

  # Turns on italic style for this text (not well supported by terminal
  # emulators).
  #
  # source://rainbow//lib/rainbow/presenter.rb#61
  def italic; end

  # source://rainbow//lib/rainbow/presenter.rb#112
  def magenta; end

  # We take care of X11 color method call here.
  # Such as #aqua, #ghostwhite.
  #
  # source://rainbow//lib/rainbow/presenter.rb#126
  def method_missing(method_name, *args); end

  # source://rainbow//lib/rainbow/presenter.rb#96
  def red; end

  # Resets terminal to default colors/backgrounds.
  #
  # It shouldn't be needed to use this method because all methods
  # append terminal reset code to end of string.
  #
  # source://rainbow//lib/rainbow/presenter.rb#40
  def reset; end

  # source://rainbow//lib/rainbow/presenter.rb#90
  def strike; end

  # Turns on underline decoration for this text.
  #
  # source://rainbow//lib/rainbow/presenter.rb#66
  def underline; end

  # source://rainbow//lib/rainbow/presenter.rb#120
  def white; end

  # source://rainbow//lib/rainbow/presenter.rb#104
  def yellow; end

  private

  # @return [Boolean]
  #
  # source://rainbow//lib/rainbow/presenter.rb#134
  def respond_to_missing?(method_name, *args); end

  # source://rainbow//lib/rainbow/presenter.rb#140
  def wrap_with_sgr(codes); end
end

# source://rainbow//lib/rainbow/presenter.rb#9
Rainbow::Presenter::TERM_EFFECTS = T.let(T.unsafe(nil), Hash)

# source://rainbow//lib/rainbow/string_utils.rb#4
class Rainbow::StringUtils
  class << self
    # source://rainbow//lib/rainbow/string_utils.rb#17
    def uncolor(string); end

    # source://rainbow//lib/rainbow/string_utils.rb#5
    def wrap_with_sgr(string, codes); end
  end
end

# source://rainbow//lib/rainbow/wrapper.rb#7
class Rainbow::Wrapper
  # @return [Wrapper] a new instance of Wrapper
  #
  # source://rainbow//lib/rainbow/wrapper.rb#10
  def initialize(enabled = T.unsafe(nil)); end

  # Returns the value of attribute enabled.
  #
  # source://rainbow//lib/rainbow/wrapper.rb#8
  def enabled; end

  # Sets the attribute enabled
  #
  # @param value the value to set the attribute enabled to.
  #
  # source://rainbow//lib/rainbow/wrapper.rb#8
  def enabled=(_arg0); end

  # source://rainbow//lib/rainbow/wrapper.rb#14
  def wrap(string); end
end

# source://rainbow//lib/rainbow/x11_color_names.rb#4
module Rainbow::X11ColorNames; end

# source://rainbow//lib/rainbow/x11_color_names.rb#5
Rainbow::X11ColorNames::NAMES = T.let(T.unsafe(nil), Hash)
