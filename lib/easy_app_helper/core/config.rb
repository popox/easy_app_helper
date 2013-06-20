################################################################################
# EasyAppHelper
#
# Copyright (c) 2013 L.Briais under MIT license
# http://opensource.org/licenses/MIT
################################################################################

require 'yaml'
require 'easy_app_helper/core/merge_policies'

class EasyAppHelper::Core::Config < EasyAppHelper::Core::Base
end

require 'easy_app_helper/core/places'

class EasyAppHelper::Core::Config < EasyAppHelper::Core::Base

  include EasyAppHelper::Core::HashesMergePolicies

  # include paths specific to the OS
  include EasyAppHelper::Core::Config::Places.get_OS_module
  ADMIN_CONFIG_FILENAME = EasyAppHelper.name


  # Potential extensions a config file can have
  CONFIG_FILE_POSSIBLE_EXTENSIONS = %w(conf yml cfg yaml CFG YML YAML Yaml)
  ADMIN_CONFIG_FILENAME
  def initialize(logger)
    super
    add_cmd_line_options
    load_config
  end

  def script_filename=(name)
    super
    [:system, :global, :user, :specific_file].each do |scope|
      internal_configs[scope] = {content: {}, source: nil, origin: nil}
    end
    force_reload
  end

  def load_config(force=false)
    super()
    load_layer_config :system, ADMIN_CONFIG_FILENAME, force
    load_layer_config :global, script_filename, force
    load_layer_config :user, script_filename, force
    load_layer_config :specific_file, internal_configs[:command_line][:content][:'config-file'], force
  end

  def force_reload
    load_config true
  end


  def to_hash
    merged_config = [:system, :global, :user].inject({}) do |temp_config, config_level|
      hashes_second_level_merge temp_config, internal_configs[config_level][:content]
    end
    if command_line_config[:'config-file']
      if command_line_config[:'config-override']
        override_merge merged_config, internal_configs[:specific_file][:content]
      else
        hashes_second_level_merge merged_config, internal_configs[:specific_file][:content]
      end

    end
    hashes_second_level_merge merged_config, command_line_config
    hashes_second_level_merge merged_config, internal_configs[:modified][:content]
  end

  def [](key)
    self.to_hash[key]
  end

  def to_yaml
    to_hash.to_yaml
  end

  #############################################################################
  private

  def add_cmd_line_options
    add_command_line_section('Configuration options') do |slop|
      slop.on 'config-file', 'Specify a config file.', :argument => true
      slop.on 'config-override', 'If specified override all other config.', :argument => false
    end
  end

  def load_layer_config(layer, filename_or_pattern, force=false)
    unless_cached(layer,  filename_or_pattern, force) do |layer, filename_or_pattern|
      fetch_config_layer layer, filename_or_pattern
    end
  end

  def fetch_config_layer(layer, filename_or_pattern)
    if filename_or_pattern.nil?
      internal_configs[layer] = {content: {}}
      filename = nil
    else
      if File.exists? filename_or_pattern
        filename = filename_or_pattern
      else
        filename = find_file POSSIBLE_PLACES[layer], filename_or_pattern
      end
      internal_configs[layer] = {content: load_config_file(filename), source: filename, origin: filename_or_pattern}
    end
  ensure
    logger.info "No config file found for layer #{layer}." if filename.nil?
  end

  def unless_cached(layer, filename_or_pattern, forced)
    cached = false
    if internal_configs[layer]
      cached = true unless internal_configs[layer][:origin] == filename_or_pattern
    end
    if forced or not cached
      yield layer, filename_or_pattern
    end
  end

  # Tries to find config files according to places (array) given and possible extensions
  def find_file(places, filename)
    return nil if places.nil?
    places.each do |dir|
      CONFIG_FILE_POSSIBLE_EXTENSIONS.each do |ext|
        filename_with_path = dir + '/' + filename + '.' + ext
        if File.exists? filename_with_path
          return filename_with_path
        else
          logger.debug "Trying \"#{filename_with_path}\" as config file."
        end
      end
    end
    nil
  end

  def load_config_file(conf_filename)
    conf = {}
    return conf if conf_filename.nil?

    begin
      logger.debug "Loading config file \"#{conf_filename}\""
      conf = Hash[YAML::load(open(conf_filename)).map { |k, v| [k.to_sym, v] }]
    rescue => e
      logger.error "Invalid config file \"#{conf_filename}\". Skipping as not respecting YAML syntax!\n#{e.message}"
    end
    conf
  end

end
