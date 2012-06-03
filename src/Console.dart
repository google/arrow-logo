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

  void showHelp() {
    writeln("  supported commands:");
    for (Primitive p in Primitive.commandsList) {
      writeln(p.name + (p.altName != null ? "  ${p.altName}" : ""));
    }
    writeln("  supported operators:");
    for (Primitive p in Primitive.operatorList) {
      writeln(p.name + (p.altName != null ? "  ${p.altName}" : ""));
    }
  }
  
  void clearText() {
    consoleElem.value = "";
  }
  
  void handleKeyPress(/* html.KeyboardEvent */ e) {
    if (NEWLINE == e.keyCode) {
      String text = consoleElem.value;
      var i = text.lastIndexOf(PROMPT);
      String code = text;
      code = code.substring(i+1);
      if (!code.isEmpty()) {
        ListNode nodes = parser.parse(code);
        writeln();
        if (mode == MODE_EVAL && isIncompleteDef(nodes.getHead())) {
          mode = MODE_DEFN;
        } else if (mode == MODE_DEFN && isCompleteDef(nodes.getHead())) {
          mode = MODE_EVAL;
        }
        if (mode == MODE_DEFN) {
          write(DEFPROMPT);
        } else {
          interpreter.eval(nodes);
          write(PROMPT);
        }
      }
      e.preventDefault();
    } else {
      // Ensure that text gets inserted at the end, by placing caret at the end.
      // Unfortunately, crashes Dartium http://code.google.com/p/dart/issues/detail?id=3364
      // consoleElem.setSelectionRange(consoleElem.textLength, consoleElem.textLength);
    }
  }
}
