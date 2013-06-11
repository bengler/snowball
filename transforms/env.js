var through = require('through');

function isEnvHack(file) {
  return /__env_hack\.js$/.test(file);
}

module.exports = function register(b, env) {
  env || (env = {});
  b.transform(function (file) {
    if (!isEnvHack(file)) return through();

    function write(buf) {}

    function end() {
      this.queue('process.env = '+JSON.stringify(env)+';');
      this.queue(null);
    }

    return through(write, end);
  })
};