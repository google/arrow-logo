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

class Console {  
  static final int MODE_EVAL = 0;
  static final int MODE_DEFN = 1;
  
  static final int NEWLINE = 0xD;
  static final String PROMPT = ">";
  static final String DEFPROMPT = "  ";

  final consoleElem;
  final Parser parser;
  Interpreter interpreter;
  int mode;
  
  Console(this.consoleElem, this.parser);
  
  void init(Interpreter interp) {
    consoleElem.on.keyPress.add(handleKeyPress);
    write(PROMPT);
    this.interpreter = interp;
    this.mode = MODE_EVAL;
  }
  
  void write(String message) {
    consoleElem.value = consoleElem.value + message;    
  }

  void writeln([String message = ""]) {
    consoleElem.value = consoleElem.value + message + "\n";    
  }

  bool isIncompleteDef(Node node) {
    if (!node.isWord()) {
      return false;
    }
    WordNode wn = node;
    return wn.isIdent() 
        && wn.getIdentName() == "INCOMPLETE_DEFINITION";
  }

  bool isCompleteDef(Node node) {
    if (!node.isWord()) {
      return false;
    }
    WordNode wn = node;
    return wn.isDefn();
  }

  void handleKeyPress(html.KeyboardEvent e) {
    if (NEWLINE == e.keyCode) {
      String text = consoleElem.value;
      var i = text.lastIndexOf(PROMPT);
      String code = text;
      code = code.substring(i+1);
      if (!code.isEmpty()) {
        ListNode node = parser.parse(code);
        writeln();
        if (mode == MODE_EVAL && isIncompleteDef(node.getHead())) {
          mode = MODE_DEFN;
        } else if (mode == MODE_DEFN && isCompleteDef(node.getHead())) {
          mode = MODE_EVAL;
        }
        if (mode == MODE_DEFN) {
          write(DEFPROMPT);
        } else {
          interpreter.eval(node);
          write(PROMPT);
        }
      }
      e.preventDefault();
    } else {
      // consoleElem.setSelectionRange(consoleElem.textLength, consoleElem.textLength);
    }
  }
}
