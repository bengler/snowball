var browserify = require("browserify"),
    jade = require("jade"),
    fs = require("fs"),
    path = require("path"),
    optimist = require('optimist'),
    bundle;

var argv = optimist
    .usage('Usage: browserify [entry files] {OPTIONS}')
    .wrap(80)
    .option('help', {
      desc : 'Show this help'
    })
    .option('require', {
        alias : 'r',
        desc : 'A module name or file to bundle.require()\n'
            + 'Optionally use a colon separator to set the target.'
    })
    .option('entry', {
        alias : 'e',
        desc : 'An entry point of your app'
    })
    .option('ignore', {
        alias : 'i',
        desc : 'Ignore a file'
    })
    .option('prelude', {
        default : true,
        type : 'boolean',
        desc : 'Include the code that defines require() in this bundle.'
    })
    .option('env', {
        type : 'string',
        desc : 'Pass one or more environment variables to the "process" object in browserified code\n'+
                'Example: --env NODE_ENV=development --env FOO=bar'
    }).argv;

if (argv.help) {
  return optimist.showHelp()
}

// Parse argv.env properly
// turns argv.env strings like ['FOO=bar', 'BAZ=qux', ...] into an object of { FOO: 'bar', BAZ:'qux' }
if (argv.env) {
  var util = require("util");
  argv.env = (util.isArray(argv.env) ? argv.env : [argv.env]).reduce(function(env, str) {
    var parts = str.split("=");
    env[parts[0]] = parts[1];
    return env;
  }, {});
}

bundle = browserify();

// Todo: make jade-support optional (consider snowball plugins?)
bundle.register('.jade', (function () {
  var compileDebug = !!(argv.env && argv.env.hasOwnProperty('NODE_ENV') && argv.env.NODE_ENV == 'development');
  return function (b, filename) {
    var body = fs.readFileSync(filename);
    var compiled;
    try {
      compiled = jade.compile(body, {
        filename: filename,
        client: true,
        compileDebug: compileDebug
      }).toString();
    }
    catch (e) {
      // There's a syntax error in the template. Wrap it into a function that will immediately throw an error
      return '\nthrow new '+ e.name +'('+JSON.stringify(e.message)+');';
    }
    // Wrap the compiled template function in a function that merges in previously registered globals (i.e. helpers, etc)
    return ''+
      'var jade = require("jade-runtime").runtime;' +
      'module.exports = function(locals, attrs, escape, rethrow, merge) {' +
      '  var locals = require("jade-runtime").globals.merge(locals);' +
      '  return ('+compiled+")(locals, attrs, escape, rethrow, merge);" +
      '}';
  }
})());

if (argv.prelude === false) {
    bundle.files = [];
    bundle.prepends = [];
}

if (argv.env) {
  // Using the browserify internal bundle.entries array - (yup, asking for trouble).
  // Todo: file a feature request for setting env variables in __browserify_process
  bundle.entries['/__browserify_process__setenv'] = {
    body: ''+
      'var __browserify_process = require("__browserify_process"),' +
      '   env = '+JSON.stringify(argv.env)+',' +
      '   hasProp = Object.prototype.hasOwnProperty;' +
      'for (var key in env) {'+
      '  if (!hasProp.call(env, key)) { continue; }'+
      '  if (hasProp.call(__browserify_process.env, key)) {'+
      '    if ((typeof console) != "undefined" && (typeof console.log) == "function") {'+
      '      console.log("Environment variable already set in browserify environment: %s", key);' +
      '    }' +
      '    continue;' +
      '  }'+
      '  __browserify_process.env[key] = env[key];'+
      '}'
  };
}

([].concat(argv.require || [])).forEach(function (req) {
    bundle.require(req);
});

if (argv.ignore) {
  bundle.ignore(argv.ignore);
}

bundle.on("syntaxError", function(e) {
  bundle.prepend('throw new SyntaxError('+JSON.stringify(e.toString())+');');
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
