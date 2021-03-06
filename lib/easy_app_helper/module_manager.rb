################################################################################
# EasyAppHelper
#
# Copyright (c) 2013 L.Briais under MIT license
# http://opensource.org/licenses/MIT
################################################################################

module EasyAppHelper::Core

end

require 'easy_app_helper/core/logger'
require 'easy_app_helper/core/base'
require 'easy_app_helper/core/config'

# This module contains the exposed methods of the framework
# It is included and extended into EasyAppHelper
module EasyAppHelper::ModuleManager

  # @return [EasyAppHelper::Core::Logger] The application logger
  def logger
    @@logger
  end

  # @return [EasyAppHelper::Core::Config] The application config
  def config
    @@config
  end

  # Convenient method that logs at info level, but also outputs the message to STDOUT if
  # verbose is set in the config.
  # @param [String] msg to be displayed
  def puts_and_logs(msg)
    @@logger.puts_and_logs msg
  end

  # Method to do something (expects a block) unless --simulate is specified on the command line.
  # See {EasyAppHelper::Core::Base#safely_exec original implementation}.
  def safely_exec(message, *args, &block)
    @@config.safely_exec message, *args, &block
  end


  def self.included(base)
    init_core_modules
    base.extend self
  end

  ################################################################################
  private

  def self.init_logger
    @@logger ||= EasyAppHelper::Core::Logger.instance
    @@logger
  end

  def self.init_config
    @@config ||= EasyAppHelper::Core::Config.new @@logger
    @@logger.set_app_config(@@config)
    @@config
  end

  def self.init_core_modules
    init_logger
    init_config
  end

end