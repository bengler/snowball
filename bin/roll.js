var browserify = require("browserify"),
  fs = require("fs"),
  path = require("path"),
  optimist = require('optimist'),
  through = require('through'),
  Combine = require('stream-combiner'),
  splitSourceMap = require("./split-source-map"),
  async = require("async"),
  concat = require('concat-stream');

var argv = optimist
  .usage('Usage: roll.js [entry files] {OPTIONS}')
  .wrap(80)
  .option('help', {
    desc: 'Show this help'
  })
  .option('entry', {
    alias: 'e',
    desc: 'An entry point of your app'
  })
  .option('raw', {
    alias: 'r',
    desc: 'Just compile entry file, without using browserify.'
  })
  .option('debug', {
    alias: 'd',
    desc: 'Enable source maps that allow you to debug your files separately.\n'
  })
  .option('externalize-source-map', {
    desc: 'Extract the source map from //@ sourceMappingURL comment. If this option is given, the source map will be' +
      ' written on the `map` key of the returned json string.\n' +
      ' This option is ony effective if --debug true\n'
  })
  .option('externalize-source-map-url', {
    desc: 'This will be the source map url as referenced by the //@ sourceMappingURL comment\n'
  })
  .option('extension', {
    desc: 'Consider files with specified EXTENSION as modules, this option can used multiple times.'
  })
  .option('transform', {
    alias: 't',
    desc: 'Source transforms to load (currently supported: jade, coffee-script)'
  })
  .option('env', {
    desc: 'Pass one or more environment variables to the "process" object in browserified code\n' +
      'Example: --env NODE_ENV=development --env FOO=bar'
  })
  .option('jserr', {
    desc: 'Output errors as JavaScript throw statements instead of writing to stderr'
  })
  .option('noparse', {
    desc: 'Don\'t parse FILE at all. This will make bundling much, much faster for giant\n' +
      'libs like jquery or threejs.\n' +
      'Example: --noparse jquery --noparse threejs'
  }).argv;

if (argv.help) {
  return optimist.showHelp()
}

function handleError(error) {
  if (argv.jserr) {
    process.stdout.write(JSON.stringify({code: 'throw new Error(' + JSON.stringify(error.toString() + "\n"+error.stack) + ');'}));
    process.exit(0)
  }
  else {
    throw error
  }
}

var entries = (argv._.concat(argv.entry).filter(Boolean));

if (entries.length == 0) {
  throw Error('No entry file given\n\n');
}

if (!fs.existsSync("./package.json")) {
  throw Error("No package.json in current working directory. Create it with npm init.")
}

var transforms = [].concat(argv.transform).filter(Boolean);
var extensions = ([].concat(argv.extension).filter(Boolean))

if (argv.raw) {
  // Don't run it through browserify itself, only run it through registered transforms

  var Module = require("module");

  // Meta module for loading transforms from the consumer's directory
  var self = new Module('snowball-consumer');
  self.paths = Module._nodeModulePaths(process.cwd());

  var loadTransform = function(trans, cb) {
    process.nextTick(function() {
      cb(null, self.require(trans))
    })
  };

  async.map(transforms, loadTransform, function(err, trFuncs){
    var trStreams = trFuncs.map(function (tr) {
      return tr(argv.entry)
    });

    var applyAllTransforms = Combine.apply(null, [fs.createReadStream(argv.entry)].concat(trStreams));

    if (argv.debug && argv['externalize-source-map']) {
      
      applyAllTransforms.pipe(splitSourceMap(argv['externalize-source-map-url'])).pipe(through(write)).pipe(process.stdout);
      function write(data) {
        this.queue(JSON.stringify(data));
      }
    }
    else {
      applyAllTransforms.pipe(concat(function (data) {
        process.stdout.write(JSON.stringify({code: data.toString()}));
        process.exit(0);
      }))
    }

  });

} else {
  var opts = {};
  opts.cache = {};

  if (argv.noparse) {
    opts.noParse = [].concat(argv.noparse).filter(Boolean)
  }
  var t = (new Date()).getTime();

  var b = browserify(opts);

  b.on('error', function (e) {
    handleError(e);
  });

  var bundleOpts = {};

  if (argv.cache) {
    var cache = {};
    // Todo: maybe use a hash of opts/argv in the cache file path
    var cacheFilePath = "./.browserify-cache";
    if (fs.existsSync(cacheFilePath)) {
      try {
        cache = JSON.parse(fs.readFileSync(cacheFilePath));
      }
      catch (e) {/* ignore */
      }
  
      // Reject cache keys where mtime has changed
      Object.keys(cache).forEach(function (key) {
        var stats = fs.statSync(key);
        if (stats.mtime.getTime() != cache[key].lastUpdated) {
          delete cache[key];
        }
      });
    }
  
    b.on('dep', function (dep) {
      dep.lastUpdated = fs.statSync(dep.id).mtime.getTime();
      cache[dep.id] = dep;
    });
    bundleOpts.cache = cache;
  }

  bundleOpts.debug = !!argv.debug;

  extensions.forEach(function (e) {
    b.extension(e)
  });

  transforms.forEach(b.transform.bind(b));
  entries.forEach(b.add.bind(b));


  var bundle = b.bundle(bundleOpts);
  bundle.on('error', handleError);

  if (argv.debug && argv['externalize-source-map']) {
    bundle.pipe(splitSourceMap(argv['externalize-source-map-url'])).pipe(through(write)).pipe(process.stdout);
    function write(data) {
      this.queue(JSON.stringify(data));
    }
  }
  else {
    bundle.pipe(concat(function (data) {
      process.stdout.write(JSON.stringify({code: data}));
    }))
  }
  if (argv.cache) {

    bundle.on('end', function () {
      // Write cache to disk
      fs.writeFile(cacheFilePath, JSON.stringify(cache));
    });
  }
}