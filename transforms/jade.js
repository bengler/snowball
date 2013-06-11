var jade = require('jade');
var through = require('through');

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
      compileDebug: true
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
      var src;
      try {
        src = compile(file, data);
      } catch (error) {
        this.emit('error', error);
      }
      this.queue(src);
      this.queue(null);
    }

    return through(write, end);
  })
};