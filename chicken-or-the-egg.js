var chicken = function () { 
  return egg();
};
var egg = function () {
  return chicken();
};
egg();
