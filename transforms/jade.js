var jade = require('jade');
var through = require('through');
var path = require('path');

function isJade(file) {
  return /\.jade$/.test(file);
}

module.exports = function register(b, opts) {
  opts || (opts = {});
  if (!opts.hasOwnProperty('compileDebug')) opts.compileDebug = true;
  function compile(file, data) {
    return jade.compile(data, {
      filename: file,
      client: true,
      compileDebug: opts.debug
    }).toString();
  }

  b.extension(".jade");
  b.transform(function (file) {
    if (!isJade(file)) return through();
    var data = '';

    function write(buf) {
      data += buf
    }

    function end() {
      var src, compiled;
      try {
        compiled = compile(file, data);
      } catch (error) {
        this.emit('error', error);
      }
      var toJsId = require("text-to-js-identifier");
      var functionName = toJsId(path.basename(file, path.extname(file)));
      src = ''+
        'var jade = require("jade-runtime").runtime;' +
        'module.exports = function template_'+functionName+'_jade(locals, attrs, escape, rethrow, merge) {' +
        '  var locals = require("jade-runtime").globals.merge(locals);' +
        '  return ('+compiled+")(locals, attrs, escape, rethrow, merge);" +
        '}';

      this.queue(src);
      this.queue(null);
    }

    return through(write, end);
  })
};