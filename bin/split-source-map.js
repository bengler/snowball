var mold = require('mold-source-map'),
    through = require('through');

function split(newMapUrl) {
  var source = "";
  function write (data) { source += data; }
  function end () {

    var molder = mold.fromSource(source);

    var d = {
      code: source.replace(molder.comment, "//@ sourceMappingURL="+newMapUrl),
      map: molder.toJSON(2)
    };
    this.queue(d);
    this.queue(null);
  }
  return through(write, end);
}

module.exports = split;