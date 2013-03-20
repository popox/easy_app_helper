# EasyAppHelper


This [gem] [1] provides a suite of helpers for command line applications.
The goal is to be as transparent as possible for the application whilst providing consistent helpers that add dedidacted behaviours to your application.

Currently the only runtime dependency is on the [Slop gem] [2].



## Installation

Add this line to your application's Gemfile:

    gem 'easy_app_helper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install easy_app_helper

## Usage

To benefit from the different helpers. Once you installed the gem, you just need to require it:

```ruby
require 'easy_app_helper'
```

And then in the "main class" of your application, include the modules you want to use and call init_app_helper in the initialize method. Then what you can do with each module is defined by each module itself.

The basic behaviour (when you include EasyAppHelper), actually adds basic command line handling (actually handled by [Slop] [2]), and provides the mechanism to enable you to add any other EasyAppHelper module.

ex:

```ruby
require 'easy_app_helper'

class MyApp
  include EasyAppHelper
  def initialize
    init_app_helper "my_app"
  end
end
```

This basically does... nothing. I mean the only behaviour it adds to your application is the ability to pass --help to the application to see the inline help (that it builds). On top of this you then have access to some other command line options like --auto, --simulate, --verbose, but for those it is up to your application to check their value using the app_config attribute which is available in your MyApp instance.

You could then do something like:

```ruby
require 'easy_app_helper'

class MyApp
  include EasyAppHelper
  def initialize
    init_app_helper "my_app", "My Super Application", "This is the application everybody was waiting for.", "1.0"
    if app_config[:verbose]
      puts "Waouh, hello World !!"
    end
  end
end
```

You can actually access any field from your application configuration through the app_config attribute.

### Other modules
Some other modules are provided:

* EasyAppHelper::Logger	provides logging facilities and config line options including log-level, log-file etc...
* EasyAppHelper::Config provides easy YAML based configuration to your script with multiple level of override (admin wide -> system wide -> user -> command line options -> --config-file). All the configuration being accessible through the app_config hash attribute

See [classes documentation] [3] for more information.

### Complete example

Here under a more complete (still useless) example using all the modules.

require 'easy_app_helper'

```ruby
class MyApp
  include EasyAppHelper
  include EasyAppHelper::Config
  include EasyAppHelper::Logger

  def initialize
    init_app_helper "my_app", "My Super Application", "This is the application everybody was waiting for.", "1.0"
    logger.info "Application is now started."
    show_config if app_config[:verbose]
  end

  def show_config
    puts "Application config is"
    puts app_config.to_yaml
  end

  def add_specifc_command_line_options(opt) 
    opt.on :s, :stupid, 'This is a very stupid option', :argument => false
  end
end

app = MyApp.new
```

With this example you can already test some of the behaviours brought to the application by the different modules.

		 $ ruby ./test_app.rb
		 
Nothing displayed

		 $ ruby ./test_app.rb --verbose
		 Application config is
		 ---
		 :verbose: true
		 :log-level: 2

Here again we see the impact of the --verbose

		 $ ruby ./test_app.rb --help

		 Usage: my_app [options]
		 My Super Application Version: 1.0

		 This is the application everybody was waiting for.
		 -- Generic options -------------------------------------------
        			--auto              Auto mode. Bypasses questions to user.
        			--simulate          Do not perform the actual underlying actions.
    			-v, --verbose           Enable verbose mode.
				  -h, --help              Displays this help.

		 -- Debug and logging options ---------------------------------
        			--debug             Run in debug mode.
        			--debug-on-err      Run in debug mode with output to stderr.
        			--log-level         Log level from 0 to 5, default 2.
        			--log-file          File to log to.

		 -- Configuration options -------------------------------------
        			--config-file       Specify a config file.

		 -- Script specific options------------------------------------
     			-s, --stupid            This is a very stupid option


Here we see that:

* each included module added its own part in the global help
* The information passed to init_app_helper has been used in order to build a consistent help.
* The method implemented add_specifc_command_line_options did add the --stupid command line option and that it fits within the global help. the syntax is the [Slop] [2] syntax, and many other options are available. See the [Slop] [2] for further info.

		 $ ruby ./test_app.rb --debug

Nothing is displayed. Why ? We used the logger.info stuff !! Just because the default log-level is 2 (Logger::Severity::WARN), whereas we did a info (Logger::Severity::INFO equals to 1).
Thus we can do a:

		 $ ruby ./test_app.rb --debug --log-level 1
I, [2013-03-20T10:58:40.819096 #13172]  INFO -- : Application is now started.

Which correctly displays the log.
Of course, as mentioned by the inline doc, this could go to a log file using the --log-file option...


### Debugging

If you want to debug what happens during the framework instanciation, you can use the DEBUG_EASY_MODULES environment variable.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


[1]: https://rubygems.org/gems/easy_app_helper        "EasyAppHelper gem"
[2]: https://rubygems.org/gems/slop        "Slop gem"
[3]: http://rubydoc.info/github/lbriais/easy_app_helper/master/frames        "EasyAppHelper documentation"