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

bundle.register('.jade', function() {
  // Hook the jade runtime object to a random key in the window object
  var jadeKey = "__jade__"+Math.random().toString(16).substring(2);
  var init = function() {
    var jadeRuntimeSource = fs.readFileSync(path.join(__dirname, "..", 'node_modules', 'jade', 'lib', 'runtime.js'));
    // yiha, code that writes code!
    buf = [];
    buf.push("window['"+jadeKey+"'] = (function() {");
    buf.push(  "var jade = { exports: {} };");
    buf.push(  "(function(module, exports) {");
    buf.push(     jadeRuntimeSource);
    buf.push(   "})(jade, jade.exports);");
    // Overwrite jade's rethrow because it uses the node.js fs module and thus will fail in browser context
    // Waiting for this https://github.com/visionmedia/jade/pull/543
    // Todo: could also consider including a sourcemapping here in debug mode
    buf.push(   "jade.exports.rethrow = function(err, filename, lineno) {");
    buf.push(     'throw new Error(err.toString()+"\\n  In "+filename+":"+lineno)');
    buf.push(   "};");
    buf.push(   "return jade.exports;");
    buf.push("})();");

    bundle.prepend(buf.join("\n"));
    init = false;
  };
  return function (b, filename) {
    var body = fs.readFileSync(filename);
    if (init) init();
    var compiled;
    try {
      compiled = jade.compile(body, {filename: filename, client: true, compileDebug: true}).toString();
    }
    catch (e) {
      // There's a syntax error in the template. Wrap it into a function that will throw an error when templates is used
      compiled = "function() {throw new Error(unescape('"+escape(e.toString()+"\nIn "+filename)+"'))}"
    }
    // Scope jade into the compiled render function by grabbing it from the window object again
    return "var jade = window['"+jadeKey+"'];module.exports="+compiled;
  }
}());

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
