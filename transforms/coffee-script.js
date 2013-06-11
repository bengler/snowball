module.exports = function register(b) {
  b.extension(".coffee");
  b.transform("coffeeify");
};
