// Copyright 2012 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Really basic CodeMirror 2 mode for logo, only keyword highlighting

CodeMirror.defineMode("logo", function(config) {
  function words(str) {
    var obj = {}, words = str.split(" ");
    for (var i = 0; i < words.length; ++i) obj[words[i]] = true;
    return obj;
  }
  var keywords = words("apply end local make output stop to repeat");
  var builtins = words(
    "back bk clean clearscreen cs equals false forward fd fput"
    + " greaterthan greaterorequal ht hideturtle help home if ifelse"
    + " lessthan lessorequal lput difference "
    + " pd pendown pu penup pi power product pr print quotient"
    + " repeat right rt run setpc setpencolor sum thing trace"
    + " true st showturtle");

  function tokenBase(stream, state) {
    var ch = stream.next();
    if (/\s/.test(ch)) {
      stream.eatWhile(/\s/);
      return null;
    }
    if (/\d/.test(ch)) {
      stream.eatWhile(/\d/);
      stream.eatWhile(/[\.]/);
      stream.eatWhile(/\d/);
      return "number";
    }
    if (/[\[\]\+\-<>=]/.test(ch)) {
      return null;
    }
    if (/[\:"]/.test(ch)) {
      stream.eatWhile(/\w/);
      return "variable";
    }
    stream.eatWhile(/\w/);
    var cur = stream.current();
    if (keywords.propertyIsEnumerable(cur)) {
      return "keyword";
    } else if (builtins.propertyIsEnumerable(cur)) {
      return "atom";
    }
    return null;
  }

  // Interface

  return {
    token: function(stream, state) {
      return tokenBase(stream, state);
    }
  };
});

CodeMirror.defineMIME("text/x-logo", "logo");
