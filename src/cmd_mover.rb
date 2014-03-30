require 'sketchup'
require 'extensions'

module CMD
  module Mover

    VERSION     = "0.6.0".freeze
    PLUGIN_ROOT = File.join(File.dirname(__FILE__), "cmd_mover")
    DICT_KEY    = "CMD::Mover".freeze
    REG_KEY     = 'CMD\Mover'.freeze

    ext = SketchupExtension.new("Mover", File.join(PLUGIN_ROOT, "mover.rb"))

    ext.version     = VERSION
    ext.copyright   = ''
    ext.creator     = ''
    ext.description = ''

    Sketchup.register_extension(ext, true)

  end # module Mover
end # module CMD
