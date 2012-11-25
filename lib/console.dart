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
part of arrowlogo;

class Console {  
  static final int MODE_EVAL = 0;
  static final int MODE_DEFN = 1;
  
  static final int NEWLINE = 0xD;
  static final int LEFT = 37;
  static final String PROMPT = "?";

  final /* html.TextAreaElement */ shellElem;
  final /* html.TextAreaElement */ historyElem;
  final /* html.TextAreaElement */ editorElem;
  final /* html.Element */ editorCommitButton;
  
  final Parser parser;
  Interpreter interpreter;
  
  String userText;

  Console(this.shellElem, this.historyElem, this.editorElem,
      this.editorCommitButton, this.parser);
  
  void init(Interpreter interp) {
    this.interpreter = interp;
    shellElem.on.keyPress.add(handleKeyPress);
    shellElem.on.keyDown.add(handleKeyDown);
    editorCommitButton.on.click.add(handleCommitClick);
    writeln("Welcome to ArrowLogo.");
    writeln("Type 'help' for help.");
    writeln("Type 'edall' to switch to the editor.");
    prompt();
  }
  
  void hideEditor() {
    editorElem.classes.add('invisible'); 
    editorCommitButton.classes.add('invisible');
    shellElem.classes.remove('invisible');
    historyElem.classes.remove('invisible');
    shellElem.focus();
  }
  
  void showEditor() {
    editorElem.classes.remove('invisible'); 
    editorCommitButton.classes.remove('invisible');
    shellElem.classes.add('invisible');
    historyElem.classes.add('invisible');
    editorElem.focus();
  }
  
  void prompt() {
    shellElem.value = PROMPT;    
  }
  
  void write(String message) {
    historyElem.value = historyElem.value.concat(message);    
  }

  void writeln([String message = ""]) {
    historyElem.value = historyElem.value.concat(message).concat("\n");    
  }

  bool isIncompleteDef(Node node) {
    if (!node.isWord()) {
      return false;
    }
    WordNode wn = node;
    return wn.stringValue == "INCOMPLETE_DEFINITION";
  }

  bool isCompleteDef(Node node) {
    return node.isDefn();
  }

  void showHelp() {
    writeln("  supported commands:");
    for (Primitive p in Primitive.commandsList) {
      writeln(p.name.concat(p.altName != null ? "  ${p.altName}" : ""));
    }
    writeln("  supported operators:");
    for (Primitive p in Primitive.operatorList) {
      writeln(p.name.concat(p.altName != null ? "  ${p.altName}" : ""));
    }
  }
  
  void clearText() {
    historyElem.value = "";
  }
  
  void handleKeyPress(/* html.KeyboardEvent */ e) {
    if (NEWLINE == e.keyCode) {
      String text = shellElem.value;
      String code = text.substring(PROMPT.length);
      if (!code.isEmpty) {
        writeln(text);
        try {
          ListNode nodes = parser.parse(code);
          interpreter.evalSequence(nodes);
        } on InterpreterException catch (ex, st) {
          writeln(ex.message);
        } on Exception catch (ex, st) {
          writeln("oops: ${ex}");
        } 
      }
      e.preventDefault();
      prompt();
    }
  }
  
  /**
   *  Ensure the cursor does not move into the prompt.
   */
  void handleKeyDown(/* html.KeyboardEvent */ e) {
    if (LEFT == e.keyCode
        && shellElem.selectionStart == PROMPT.length
        && shellElem.selectionEnd == PROMPT.length) {
      e.preventDefault();
    }
  }
  
  void handleCommitClick(/* html.Event */ e) {
    userText = editorElem.value;
    ListNode nodes = parser.parse(userText);
    List<Node> nonDefnNodes = [];
    String names = "";
    for (Node n in nodes) {
      if (n.isDefn()) {
        DefnNode defn = n;
        interpreter.define(defn);
        if (names.isEmpty) {
          names = defn.name;
        } else {
          names = names.concat(", ${defn.name}");
        }
      } else {
        nonDefnNodes.add(n);
      }
    }
    ListNode nodesToEval = ListNode.makeList(nonDefnNodes);
    interpreter.evalSequence(nodesToEval);
    if (!names.isEmpty) {
      writeln("You defined $names");
    }
    if (!nodesToEval.isNil()) {
      writeln("Executing $nodesToEval");
    }
    hideEditor();
  }
}
