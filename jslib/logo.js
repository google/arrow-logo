CodeMirror.defineMode("logo", function(config) {
  function words(str) {
    var obj = {}, words = str.split(" ");
    for (var i = 0; i < words.length; ++i) obj[words[i]] = true;
    return obj;
  }
  var keywords = words(
    "apply back bk clean clearscreen cs equals false forward fd fput "
    + " greaterthan greaterorequal ht hideturtle help home if ifelse "
    + " lessthan lessorequal local lput difference make output "
    + " pd pendown pu penup pi power product pr print quotient "
    + " repeat right rt run setpc setpencolor stop sum thing trace"
    + " true st showturtle");

  var curPunc;
  function tokenBase(stream, state) {
    var ch = stream.next();
    if (/\d/.test(ch)) {
      stream.eatWhile(/[\.]/);
      stream.eatWhile(/\d/);
      return "number";
    }
    if (/[\:"]/.test(ch)) {
      stream.skipTo(" ");
      return "variable";
    }
    stream.skipTo(" ");
    var cur = stream.current();
    if (keywords.propertyIsEnumerable(cur)) {
      return "keyword";
    }
    return "atom";
  }

  // Interface

  return {
    token: function(stream, state) {
      return tokenBase(stream, state);
    }
  };
});

CodeMirror.defineMIME("text/x-logo", "logo");
