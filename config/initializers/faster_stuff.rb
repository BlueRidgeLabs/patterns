# frozen_string_literal: true

# soon we'll have faster_path
if Gem.loaded_specs.key? 'faster_path'
  require 'faster_path/optional/monkeypatches'
  FasterPath.sledgehammer_everything!
end
