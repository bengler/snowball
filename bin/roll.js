var browserify = require("browserify"),
    fs = require("fs"),
    path = require("path"),
    optimist = require('optimist');

var argv = optimist
    .usage('Usage: browserify [entry files] {OPTIONS}')
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
    .option('transform', {
        alias : 't',
        desc : 'Source transforms to load (currently supported: jade, coffee-script)'
    })
    .option('env', {
        type : 'string',
        desc : 'Pass one or more environment variables to the "process" object in browserified code\n'+
                'Example: --env NODE_ENV=development --env FOO=bar'
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


var b = browserify();

b.on('error', function(e) {
  process.stdout.write('throw new Error('+ JSON.stringify(e.toString()) +')');
  process.exit(0)
});

([].concat(argv.transform || [])).forEach(function(transform) {
  require("../transforms/"+transform)(b);
});

(argv._.concat(argv.entry || [])).forEach(function (entry) {
  b.add(entry);
});

var bundle = b.bundle();

bundle.on('error', function(e) {
  process.stdout.write('throw new Error('+ JSON.stringify(e.toString()) +')');
  process.exit(0)
});

var buf = "";
bundle.on('data', function(chunk) {
  buf += chunk;
});

bundle.on('end', function() {
  process.stdout.write(buf)
});

