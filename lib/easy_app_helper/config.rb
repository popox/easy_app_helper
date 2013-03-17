################################################################################
# EasyAppHelper 
#
# Copyright (c) 2013 L.Briais under MIT license
# http://opensource.org/licenses/MIT
################################################################################

# Config file format
require 'yaml'

# This module defines:
# - Some basic command line options(see --help), with their underlying
#   mechanism.
# - A mechanism (based on Slop) to add your own command line options.
# - A generated inline help.
# This module provides the following 5 levels of configuration:
# - Admin wide YAML config file, for options common to all your EasyAppHelper applications
# - System wide YAML config file.
# - User YAML config file.
# - Command line options.
# - Command line supplied YAML config file(any option defined here will override the previous).
# All these 5 levels of configuration override with consistent override mechanism. 
# Config files are in YAML but can have different extensions.
module EasyAppHelper::Config

  include EasyAppHelper::Common

  # Where could be stored admin configuration that rules all EasyAppHelper
  # based applications.
  self::ADMIN_CONFIG_POSSIBLE_PLACES = ["/etc"]
  self::ADMIN_CONFIG_FILENAME = EasyAppHelper.name

  # Where could be stored system wide configuration
  self::SYSTEM_CONFIG_POSSIBLE_PLACES = ["/etc",
                                         "/usr/local/etc"]
  # Where could be stored user configuration
  self::USER_CONFIG_POSSIBLE_PLACES = ["#{ENV['HOME']}/.config"]
  
  # Potential extensions a config file can have
  self::CONFIG_FILE_POSSIBLE_EXTENSIONS = ['conf', 'yml', 'cfg', 'yaml', 'CFG', 'YML', 'YAML', 'Yaml']

  # Loads the configuration files (admin, system, user).
  #
  # Config files may define any type of structure supported by YAML.
  # The override policy is that, if an entry in the config is a hash and the next
  # level defines the same hash, they are merged.
  # For any other type (scalar, array), the overrider... overrides ;)
  #
  # Config files can be at different places and have different extensions (see
  # CONFIG_FILE_POSSIBLE_EXTENSIONS). They have the same base name as the script_filename.
  def self.provides_config(script_filename, app_name, app_description, app_version)
    config = load_admin_wide_config 
    config = EasyAppHelper::Common.override_config config, load_system_wide_config(script_filename)
    EasyAppHelper::Common.override_config config, load_user_config(script_filename)
  end

  # If the option --config-file has been specified, it will be loaded and override
  # current configuration according to rules
  def load_custom_config
    return unless app_config[:'config-file']
    begin
      @app_config = EasyAppHelper::Common.override_config app_config, EasyAppHelper::Config.load_config_file(app_config[:'config-file'])
    rescue => e
      err_msg = "Problem with \"#{app_config[:'config-file']}\" config file!\n#{e.message}\nIgnoring..."
      logger.error err_msg
    end
  end

  # Adds a command line options for this module.
  # - +--config-file+ +filename+ To specify a config file from the command line.
  def self.add_cmd_line_options(slop_definition)
    slop_definition.separator "\n-- Configuration options -------------------------------------"
    slop_definition.on 'config-file', 'Specify a config file.', :argument => true
  end

  # Used by the framework
  def self.module_entry_point
    :load_custom_config
  end


  ################################################################################
  private 

  # Reads config from admin config file.
  def self.load_admin_wide_config
    load_config_file find_file ADMIN_CONFIG_POSSIBLE_PLACES, ADMIN_CONFIG_FILENAME
  end

  # Reads config from system config file.
  def self.load_system_wide_config(script_filename)
    load_config_file find_file SYSTEM_CONFIG_POSSIBLE_PLACES, script_filename
  end

  # Reads config from user config file.
  def self.load_user_config(script_filename)
    load_config_file find_file USER_CONFIG_POSSIBLE_PLACES, script_filename
  end

  # Loads a config file.
  def self.load_config_file(conf_filename)
    return {} if conf_filename.nil? 
    # A file exists
    Hash[YAML::load(open(conf_filename)).map { |k, v| [k.to_sym, v] }]
  end

  # Tries to find config files according to places (array) given and possible extensions
  def self.find_file(places, filename)
    places.each do |dir|
      CONFIG_FILE_POSSIBLE_EXTENSIONS.each do |ext|
        filename_with_path = dir + '/' + filename + '.' + ext
        if File.exists? filename_with_path
          return filename_with_path
        end
      end
    end
    nil
  end


end
