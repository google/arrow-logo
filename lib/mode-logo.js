ace.define('ace/mode/logo', function(require, exports, module) {
  "use strict";

  var oop = require("ace/lib/oop");
  var TextMode = require("ace/mode/text").Mode;
  var Tokenizer = require("ace/tokenizer").Tokenizer;
  var LogoHighlightRules = require("ace/mode/logo_highlight_rules").LogoHighlightRules;

  var Mode = function() {
    this.$tokenizer = new Tokenizer(new LogoHighlightRules().getRules());
  };
  oop.inherits(Mode, TextMode);

  (function() {
    this.lineCommentStart = ";";

    // Whenever the line starts with "to ", i.e. it is a definition, add indent.
    this.getNextLineIndent = function(state, line, tab) {
      var indent = this.$getIndent(line)
      if (line.indexOf("to ") === 0)
        return ("  " + indent)
      if (line.indexOf("  end") === 0)
        return "";
      return indent;
    };
  }).call(Mode.prototype);

  exports.Mode = Mode;
});

ace.define('ace/mode/logo_highlight_rules', function(require, exports, module) {
  "use strict";

  var oop = require("ace/lib/oop");
  var TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules;

  var LogoHighlightRules = function() {

    this.$rules = {
      "start": [
        {
          token : "comment",
          regex : ";.*$"
        },
        {
          token: "constant.number",
          regex: "[0-9]+(?:\\.[0-9]+)?"
        }, {
          token: "keyword",
          regex: "[a-zA-Z]+"
        }, {
          token: "variable",
          regex: "\\:[a-zA-Z]+"
        }, {
          token: "string",
          regex: "\"[a-zA-Z0-9]+",
        }
      ]
    };

    /*this.$rules = {
       "start" : [
         {
           token : "comment",
           regex : "/\\*",
           next : "comment"
         },
         {
           token : "comment",
           regex : "//.*$"
         },
       ],

       ],
       "qqString" : [
         {
           token : "string",
           regex : "[^\\\\\"]*(?:\\\\.[^\\\\\"]*)*\"",
           next : "start"
         }
       ]
       };*/
  }

  oop.inherits(LogoHighlightRules, TextHighlightRules);

  exports.LogoHighlightRules = LogoHighlightRules;
});