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
library console;

import 'dart:html' as html;
import 'dart:isolate';

import "interpreter.dart";
import "nodes.dart";
import "parser.dart";
import "scope.dart";

class Console {
  
  static final int NEWLINE = 0xD;
  static final int LEFT = 37;
  static final String PROMPT = "?";

  final html.TextAreaElement shellElem;
  final html.TextAreaElement historyElem;
  final html.TextAreaElement editorElem;
  final html.Element editorCommitButton;
  
  final Parser parser;
  SendPort interpreterPort;
  Interpreter interpreter;
  
  String userText;

  Console(SendPort interpreterPort)
      : shellElem = html.document.query('#shell'),
        historyElem = html.document.query('#history'),
        editorElem = html.document.query('#editor'),
        editorCommitButton  = html.document.query('#commit'),
        parser = new Parser(Primitive.makeTopLevel()) {
    shellElem.focus();
    this.interpreterPort = interpreterPort;
    shellElem.on.keyPress.add(handleKeyPress);
    shellElem.on.keyDown.add(handleKeyDown);
    editorCommitButton.on.click.add(handleCommitClick);
    writeln("Welcome to ArrowLogo.");
    writeln("Type 'help' for help.");
    writeln("Type 'edall' to switch to the editor.");
    prompt();
  }
  
  void receiveFun(dynamic raw, SendPort replyTo) {
    print("console $raw");
    List msg = raw;
    Primitive p = Primitive.lookup(msg[0]);
    switch (p) {
      case Primitive.CLEARTEXT:
        clearText();
        break;
        
      case Primitive.EDALL:
        showEditor();
        break;

      case Primitive.HELP:
        showHelp();
        break;
        
      case Primitive.PRINT:
        writeln(msg[1]);
        break;
    }
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
        // TODO: get back errors
        interpreterPort.send([code]);
      }
      e.preventDefault();
      prompt();
    }
  }
  
  /**
   *  Ensure the cursor does not move into the prompt.
   */
  void handleKeyDown(html.KeyboardEvent e) {
    if (LEFT == e.keyCode
        && shellElem.selectionStart == PROMPT.length
        && shellElem.selectionEnd == PROMPT.length) {
      e.preventDefault();
    }
  }
  
  void handleCommitClick(html.Event e) {
    userText = editorElem.value;
    ListNode nodes;
    
    try {
      nodes = parser.parse(userText);
    } on Exception catch (ex) {
      html.window.alert("parse error $ex");
    }
    // no parse error, 
    interpreterPort.send(userText);

    List<Node> nonDefnNodes = [];
    String names = "";
    for (Node n in nodes) {
      if (n.isDefn()) {
        DefnNode defn = n;
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
    if (!names.isEmpty) {
      writeln("You defined $names");
    }
    if (!nodesToEval.isNil()) {
      writeln("Executing $nodesToEval");
    }
    
    hideEditor();
  }
}
