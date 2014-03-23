require 'sketchup'
require 'extensions'

module CMD
  module Mover

    VERSION = "0.6.0".freeze
    PLUGIN_ROOT = File.join(File.dirname(__FILE__), "cmd_mover")

    ext = SketchupExtension.new("Mover", File.join(PLUGIN_ROOT, "mover.rb"))
    ext.version = VERSION
    Sketchup.register_extension(ext, true)

  end # module Mover
end # module CMD
