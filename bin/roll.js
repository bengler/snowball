var browserify = require("browserify"),
    fs = require("fs"),
    path = require("path"),
    optimist = require('optimist');

var argv = optimist
    .usage('Usage: roll.js [entry files] {OPTIONS}')
    .wrap(80)
    .option('help', {
      desc : 'Show this help'
    })
    .option('entry', {
        alias : 'e',
        desc : 'An entry point of your app'
    })
    .option('raw', {
      alias : 'r',
      desc : 'Just compile entry file, without using browserify.'
    })
    .option('debug', {
      alias : 'd',
      desc : 'Enable source maps that allow you to debug your files separately.\n'
    })
    .option('transform', {
        alias : 't',
        desc : 'Source transforms to load (currently supported: jade, coffee-script)'
    })
    .option('env', {
        desc : 'Pass one or more environment variables to the "process" object in browserified code\n'+
                'Example: --env NODE_ENV=development --env FOO=bar'
    })
    .option('noparse', {
        desc : 'Don\'t parse FILE at all. This will make bundling much, much faster for giant\n'+
                'libs like jquery or threejs.\n'+
                'Example: --noparse jquery --noparse threejs'
    }).argv;

if (argv.help) {
  return optimist.showHelp()
}

if (argv.raw) {
  var compilers = {
    coffee: function (data) {
      var coffee = require("coffee-script");
      return coffee.compile(data);
    }
  };
  (argv._.concat(argv.entry || [])).forEach(function (entry) {
    // todo: keep a map of extension => compiler instead (in order to support jade compiling too)
    var compile = compilers[path.extname(entry).replace(/^\./, "")];
    fs.readFile(entry, function (err, data) {
      if (err) throw err;
      if (compile) data = compile(data.toString());
      process.stdout.write("\n");
      process.stdout.write(data);
      process.stdout.write("\n");
    });
  });
  return;
}

var opts = {};
opts.cache = {};
if (argv.noparse) {
  opts.noParse = argv.noparse;
}

var b = browserify(opts);

b.on('error', function(e) {
  process.stdout.write('throw new Error('+ JSON.stringify(e.toString()) +');');
  process.exit(0)
});

var cache = {};
// Todo: maybe use a hash of opts/argv in the cache file path
var cacheFilePath = "./.browserify-cache";
if (fs.existsSync(cacheFilePath)) {
  cache = JSON.parse(fs.readFileSync(cacheFilePath));
  // Reject cache keys where mtime has changed
  Object.keys(cache).forEach(function(key) {
    fs.stat(key, function(err, stats) {
      if (err || stats.mtime.getTime() != cache[key].lastUpdated) {
       delete cache[key]; 
      }
    })
  });
}

b.on('dep', function(row) {
  row.lastUpdated = fs.statSync(row.id).mtime.getTime();
  cache[row.id] = row;
});

([].concat(argv.transform || [])).forEach(function(transform) {
  require("../transforms/"+transform)(b);
});

(argv._.concat(argv.entry || [])).forEach(function (entry) {
  b.add(entry);
});

if (argv.env) {
  var envify = require('envify/custom');
  // Parse argv.env properly
  // turns argv.env strings like ['FOO=bar', 'BAZ=qux', ...] into an object of { FOO: 'bar', BAZ:'qux' }
  var util = require("util");
  var vars = (util.isArray(argv.env) ? argv.env : [argv.env]).reduce(function(env, str) {
    var parts = str.split("=");
    env[parts[0]] = parts[1];
    return env;
  }, {});
  b.transform(envify(vars));
}

var bundleOpts = {};
bundleOpts.cache = cache;

if (argv.debug) {
  bundleOpts.debug = argv.debug;
}

var bundle = b.bundle(bundleOpts);

bundle.on('error', function(e) {
  process.stdout.write('throw new Error('+ JSON.stringify(e.toString()) +');');
  //process.exit(0)
});

var buf = "";
bundle.on('data', function(chunk) {
  buf += chunk;
});

bundle.on('end', function() {
  process.stdout.write(buf)
});

bundle.on('end', function() {
  // Write cache to disk
  fs.writeFile(cacheFilePath, JSON.stringify(cache));
});
