```
                         _           _ _ 
 ___ _ __   _____      _| |__   __ _| | |
/ __| '_ \ / _ \ \ /\ / / '_ \ / _` | | |
\__ \ | | | (_) \ V  V /| |_) | (_| | | |
|___/_| |_|\___/ \_/\_/ |_.__/ \__,_|_|_|
Makes your front-end code roll
```

With snowball you can:
  - Use npm for dependency management
  - Run your client side javascript on a server with ease (i.e. running tests on a CI server)
  - Serve pre-defined bundles through sinatra
  - Compile and minifiy all your javascript bundles in a pre-deploy step

# Why?
  - Because Sprockets kinda works only when you depend on very few javascript libraries
  - Because npm is really good at managing dependencies
  
### But i need a javascript library that is not available through npm?
  Oh, no problem! You can still require reqular files in your bundle files like this:
  
```js
  require("./path/to/my-esoteric-lib.js")
```
The only thing you need to make sure is that your esoteric library follows the [CommonJS / Modules spec](http://wiki.commonjs.org/wiki/Modules/1.1) and adds itself to the `exports` object. Something like this will do the trick:
```js
  exports.MyAPI = MyAPI
```

## Installation

Add this line to your application's Gemfile:

    gem 'snowball'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snowball

## Usage

# Define a bundle

Defining a bundle is as easy as creating a javascript file and require() your dependencies. Then you just 
add the containing folder to the Snowball search path, configure the endpoint you'd like to
serve bundles from, and you are good to go.

I.e. given the follwing project layout:

```
myapp
  |- js
      |- all.js
```
```js
          var $ = require("jquery");
          var Backbone = require("backbone");
          var myJsApp = require("myjsapp").App;
          myJsApp.init()
```
```
      |- minimal.js
```
```js
          var $ = require("jquery");
          var myTinyVersion = require("tinyapp").TinyApp;
          myTinyVersion.init();
```
```
  |- my_app.rb
```
```ruby
    class MyApp extends Sinatra::Base
      register Sinatra::Snowball
      snowball do
        set_serve_path "/assets"
        add_load_path "js"
      end
      # (...)
    end
```

Now your bundles are available from /bundles/all.js and /bundles/minimal.js and all dependencies are automatically
resolved and concatenated into that file

# Precompiling bundles pre-deploy

Example rake task that takes a an entry file, concatenates and compresses it to a target file.

```ruby
namespace :snowball do
  target = './public/bundle1.js'
  entryfile = './app/assets/js/bundle1.coffee'

  desc "Roll a new javascript bundle"
  task :roll do
    require "uglifier"
    require "snowball/roller"
    puts "Rolling..."
    File.open(target, 'w') do |f|
      f.write(Uglifier.compile(Snowball::Roller.new(entryfile).roll))
    end
    puts "Done!"
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request