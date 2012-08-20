var browserify = require("browserify"),
    jade = require("jade"),
    fs = require("fs"),
    path = require("path"),
    bundle;

var argv = require('optimist')
    .usage('Usage: node roll.js [entry files] {OPTIONS}')
    .wrap(80)
    .option('ignore', {
        alias : 'i',
        desc : 'Ignore a file'
    })
    .option('entry', {
        alias : 'e',
        desc : 'An entry point of your app'
    }).argv;

bundle = browserify();

bundle.register('.jade', function (b, filename) {
  var body = fs.readFileSync(filename);
  var compiled;
  try {
    compiled = jade.compile(body, {filename: filename, client: true, compileDebug: true}).toString();
  }
  catch (e) {
    // There's a syntax error in the template. Wrap it into a function that will throw an error when templates is used
    compiled = "function() {throw new Error(unescape('"+escape(e.toString()+"\nIn "+filename)+"'))}"
  }
  // Wrap the compiled template function in a function that merges in previously registered globals (i.e. helpers, etc)
  return ''+
    'var jade = require("jade-runtime").runtime;' +
    'module.exports = function(locals, attrs, escape, rethrow, merge) {' +
    '  var locals = require("jade-runtime").globals.merge(locals);' +
    '  ('+compiled+")(locals, attrs, escape, rethrow, merge);" +
    '}';
  }
);

if (argv.ignore) {
  bundle.ignore(argv.ignore);
}

bundle.on("loadError", function(e) {
  bundle.prepend('\nthrow new Error('+JSON.stringify(e.message)+');');
});

bundle.on("syntaxError", function(e) {
  bundle.prepend('throw new Error('+JSON.stringify(e.message)+');');
});

(argv._.concat(argv.entry || [])).forEach(function (entry) {
  try {
    bundle.addEntry(entry);
  }
  catch (e) {
    bundle.emit("loadError", e);
  }
});

// Write bundle on nextTick since browserify events are emitted on process.nextTick
process.nextTick(function() {
  process.stdout.write(bundle.bundle());  
});
