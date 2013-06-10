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
    .option('env', {
        type : 'string',
        desc : 'Pass one or more environment variables to the "process" object in browserified code\n'+
                'Example: --env NODE_ENV=development --env FOO=bar'
    }).argv;

if (argv.help) {
  return optimist.showHelp()
}


var b = browserify("./"+argv.entry);

if (argv.entry.match(/\.coffee$/)) b.extension(".coffee");

b.transform("coffeeify");

var bundle = b.bundle()
bundle.on('error', function(e) {
  process.stdout.write('throw new SyntaxError("'+ e +'")');
  process.exit(0)
});

bundle.pipe(process.stdout);