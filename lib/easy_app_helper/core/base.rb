################################################################################
# EasyAppHelper
#
# Copyright (c) 2013 L.Briais under MIT license
# http://opensource.org/licenses/MIT
################################################################################

require 'slop'

# This class is the base class for the {EasyAppHelper::Core::Config config} object.
# It handles the internal_configs hash that actually contains all configurations read from
# various sources: command line, config files etc...

class EasyAppHelper::Core::Base
  CHANGED_BY_CODE = 'Changed by code'
  INTRODUCED_SORTED_LAYERS = [:modified, :command_line]

  attr_reader :script_filename, :app_name, :app_version, :app_description, :internal_configs, :logger

  def initialize(logger)
    @app_name = @app_version = @app_description = ""
    @script_filename = File.basename $0, '.*'
    @internal_configs = {:modified => {:content => {}, :source => CHANGED_BY_CODE}}
    @logger = logger
    @slop_definition = Slop.new
    build_command_line_options
  end


  # @return [String] The formatted command line help
  def help
    @slop_definition.to_s
  end

  # sets the filename while maintaining the slop definition upto date
  # @param [String] filename
  def script_filename=(filename)
    @script_filename = filename
    @slop_definition.banner = build_banner
  end
  # sets the application name used for logging while maintaining the slop definition upto date
  # @param [String] fname
  def app_name=(name)
    @app_name = name
    @slop_definition.banner = build_banner
  end
  # sets the version while maintaining the slop definition upto date
  # @param [String] version
  def app_version=(version)
    @app_version = version
    @slop_definition.banner = build_banner
  end
  # sets the filename while maintaining the slop definition upto date
  # @param [String] description
  def app_description=(description)
    @app_description = description
    @slop_definition.banner = build_banner
  end

  # helper to add in one command any of the four base properties used
  # by the logger and the config objects.
  # @param [String] app_name
  # @param [String] script_filename
  # @param [String] app_version
  # @param [String] app_description
  def describes_application(app_name = nil, script_filename = nil, app_version = nil, app_description = nil)
    self.app_name = app_name unless app_name.nil?
    self.app_version = app_version unless app_version.nil?
    self.app_description = app_description unless app_description.nil?
    self.script_filename = script_filename unless script_filename.nil?
  end

  # @return [Hash] This hash built from slop definition correspond to the :command_line layer of internal_configs
  def command_line_config
    @slop_definition.parse
    @slop_definition.to_hash
  end

  # Yields a slop definition to modify the command line parameters
  # @param [String] title used to insert a slop separator
  def add_command_line_section(title='Script specific')
    raise "Incorrect usage" unless block_given?
    @slop_definition.separator build_separator(title)
    yield @slop_definition
  ensure
    sync!
  end

  # Sets the :command_line layer of internal_configs to the computed {#command_line_config}
  def load_config
    sync!
    self
  end

  # Convenient method to set a value in a particular layer
  # If the layer does not exist it is correctly created and filled in with the key/value couple
  def set_value key, value, layer = nil
    if layer.nil?
      self[key] = value
      return
    end
    unless layers.include? layer
      internal_configs[layer] = {:content => {}, :source => 'Unknown source'}
      logger.warn "Trying to modify a non existing config layer: \"#{layer.to_s}\". Automatically creating it..."
    end
    internal_configs[layer][:content][key] = value
  end

  def get_value key, layer = nil
    if layer.nil?
      return self[key]
    end
    res = nil
    begin
      res = internal_configs[layer][:content][key]
    rescue => e
      logger.warn "Trying to reading from a non existing config layer: \"#{layer}\". Returning nil for the key \"#{key}\"..."
    end
    res
  end



  # Any modification done to the config is in fact stored in the :modified layer of internal_configs
  # @param [String] key
  # @param [String] value
  def []=(key,value)
    internal_configs[:modified][:content][key] = value unless check_hardcoded_properties key, value
  end

  # Reset the :modified layer of internal_configs rolling back any change done to the config
  def reset
    internal_configs[:modified] = {:content => {}, :source => CHANGED_BY_CODE}
    self
  end


  # @return [Array] List of layers
  def layers
    res = self.class.layers
    internal_configs.keys.each do |layer|
      next if res.include? layer
      res << layer
    end
    res
  end

  def self.layers
    res = []
    self.ancestors.each do |klass|
      next unless klass.is_a? Class
      break if EasyAppHelper::Core::Base < klass
      res << klass::INTRODUCED_SORTED_LAYERS.reverse
    end
    res.flatten.reverse
  end


  def find_layer(key)
    layers.each do |layer|
      return layer if internal_configs[layer][:content][key]
    end
    nil
  end


  # Executes code (block given) unless :simulate is in the config.
  # If :simulate specified then display message instead of executing the code (block).
  def safely_exec(message, *args)
    raise "No block given" unless block_given?
    if self[:simulate]
      logger.puts_and_logs "SIMULATING: #{message}" unless message.nil?
    else
      logger.puts_and_logs message
      yield(*args)
    end
  end


  private

  def sync!
    internal_configs[:command_line] = {:content => command_line_config, :source => 'Command line'}
  end


  # Performs actions related the very specific config parameters
  # @param [String] key The parameter to check
  # @param [Object] value The value it expects to be set to
  # @param [Symbol] layer Optional layer, default is :modified
  # @return [Boolean] Whether or not the internal state has been changed
  def check_hardcoded_properties(key, value, layer = :modified)
    processed = false
    case key
      when :'log-level'
        logger.send :level=, value, false
      when :'config-file'
        set_value key, value, layer
        force_reload
        processed = true
    end
    processed
  end

  # Builds a nice separator
  def build_separator(title, width = 80, filler = '-')
    "#{filler * 2} #{title} ".ljust width, filler
  end

  # Builds common used command line options
  def build_command_line_options
    add_command_line_section('Generic options') do |slop|
      slop.on :auto, 'Auto mode. Bypasses questions to user.', :argument => false
      slop.on :simulate, 'Do not perform the actual underlying actions.', :argument => false
      slop.on :v, :verbose, 'Enable verbose mode.', :argument => false
      slop.on :h, :help, 'Displays this help.', :argument => false
    end
  end

  def build_banner
    "\nUsage: #{script_filename} [options]\n#{app_name} Version: #{app_version}\n\n#{app_description}"
  end

end