```
                              ______        ___________
_______________________      ____  /_______ ___  /__  /
__  ___/_  __ \  __ \_ | /| / /_  __ \  __ `/_  /__  / 
_(__  )_  / / / /_/ /_ |/ |/ /_  /_/ / /_/ /_  / _  /  
/____/ /_/ /_/\____/____/|__/ /_.___/\__,_/ /_/  /_/  
                                                              
  Makes your front-end code roll
```

[![Build Status](https://travis-ci.org/bengler/snowball.png?branch=master)](https://travis-ci.org/bengler/snowball)

# What?
Snowball enables you to:

  - Use npm for dependency management
  - Run your front-end javascript on a server with ease (i.e. running tests on a CI server)
  - Serve pre-defined bundles through Sinatra in development
  - Compile and minifiy all your JavaScript in a pre-deploy step
  - Write your front-end code in CoffeeScript
  - Serve pre-compiled Jade templates for your front-end

# Why?
Because:

  - [Sprockets](https://github.com/sstephenson/sprockets) is kinda cumbersome when you have a large number of dependencies.
  - [npm](http://npmjs.org) is really really good at managing dependencies for you.

# How?
  - It uses [browserify](https://github.com/substack/node-browserify) magic to search your code for require() statements and figure
    out which dependencies to include in the bundle.

## FAQ

### Oh, but I depend on a javascript library that is not in the npm repository!

No problem, really! You can still require reqular files in your bundle files like this:
  
```js
  require("./path/to/my-esoteric-lib.js")
```

### Oh, but I have a lot of javascript code that is not written as Node modules!

Really? Then you should start converting right away.

The only thing you need to make sure is that your esoteric library follows the [CommonJS / Modules spec](http://wiki.commonjs.org/wiki/Modules/1.1) 
and adds itself to the `exports` object. This is how [underscore.js](http://underscorejs.org/docs/underscore.html#section-10) does that:
```js
if (typeof exports !== 'undefined') {
  if (typeof module !== 'undefined' && module.exports) {
    exports = module.exports = _;
  }
  exports._ = _;
} else {
  root['_'] = _;
}
```

## Installation

Add this line to your application's Gemfile:

    gem 'snowball'

And then execute:

    $ bundle

## Usage example

```ruby
    class MyApp extends Sinatra::Base
      register Sinatra::Snowball
      snowball do
        # Serve bundles from this local folder
        source_path "spec/fixtures/js"

        # Map the source path over to this public http path
        http_path "/js"

        # Support coffeescript
        transforms ['coffee-script']

        # Support the `coffee` file extension so we can do require("./foo") to require ./foo.coffee 
        extensions ['coffee']

        # Don't parse the jquery source for require() so we avoid things like jsdom getting bundled with our package
        noparse [:jquery]

        # Specific configuration options when the *requested* filename matches foo.js
        match 'foo.js' do
          # Serve this file as is, without browserify-ing it 
          raw true
        end
    end
```

Now your bundles are available from /bundles/all.js and /bundles/minimal.js and all dependencies are automatically
resolved and concatenated into that file

# TODO (OUTDATED): Precompiling bundles pre-deploy

Example rake task that takes a an entry file, concatenates and compresses it to a target file.

```ruby
namespace :snowball do
  target = './public/all.js'
  entryfile = './js/all.coffee'

  desc "Roll a new javascript bundle"
  task :roll do
    require "uglifier"
    require "snowball/roller"
    puts "Rolling..."
    File.open(target, 'w') do |f|
      f.write(Uglifier.compile(Snowball::Roller.roll(entryfile, Snowball::Config.new)))
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
