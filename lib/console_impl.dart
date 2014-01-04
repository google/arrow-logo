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
library console_impl;

import 'dart:html' as html;
import 'dart:js';

import 'console.dart';
import 'interpreter.dart';
import 'nodes.dart';
import 'parser.dart';

class ConsoleImpl extends Console {
  
  static final int NEWLINE = 0xD;
  static final int LEFT = 37;
  static final String PROMPT = "?";

  final html.TextAreaElement shellElem;
  final html.TextAreaElement historyElem;
  final html.TextAreaElement editorElem;
  final html.Element editorBackground;
  final html.Element editorCommitButton;
  JsObject jsCodeMirrorInstance;
  
  final Parser parser;
  InterpreterInterface interpreter;
  
  String userText;

  ConsoleImpl(this.interpreter)
      : shellElem = html.document.querySelector('#shell'),
        historyElem = html.document.querySelector('#history'),
        editorElem = html.document.querySelector('#editor'),
        editorBackground = html.document.querySelector("#editorBackground"),
        editorCommitButton  = html.document.querySelector('#commit'),
        parser = new Parser(Primitive.makeTopLevel()) {
    shellElem.focus();
    shellElem.onKeyPress.listen(handleKeyPress);
    shellElem.onKeyDown.listen(handleKeyDown);
    editorCommitButton.onClick.listen(handleCommitClick);
    writeln("Welcome to ArrowLogo.");
    writeln("Type 'help' for help.");
    writeln("Type 'edall' to switch to the editor.");
    prompt();
  }
  
  void receive(dynamic raw) {
    if (raw is Map) {
      Map map = raw;
      if (map.containsKey("exception")) {
        writeln(map["exception"]);
      } else if (map.containsKey("defined")) {
        String name = map["defined"];
        writeln("You defined $name");
      } else if (map.containsKey("trace")) {
        String trace = map["trace"];
        writeln(trace);
      } 
      return;
    }
    if (raw is String) {
      writeln(raw);
      return;
    }
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
    editorBackground.classes.add('invisible');
    editorElem.classes.add('invisible'); 
    editorCommitButton.classes.add('invisible');
    shellElem.classes.remove('invisible');
    historyElem.classes.remove('invisible');
    shellElem.focus();
  }
  
  void showEditor() {
    editorBackground.classes.remove('invisible'); 
    editorElem.classes.remove('invisible'); 
    editorCommitButton.classes.remove('invisible');
    shellElem.classes.add('invisible');
    historyElem.classes.add('invisible');
    editorElem.focus();
    
    jsCodeMirrorInstance = new JsObject(context['Glue']).callMethod('showCmEditor');
  }
  
  void prompt() {
    shellElem.value = PROMPT;    
  }
  
  void write(String message) {
    historyElem.value = historyElem.value + message;    
  }

  void writeln([String message = ""]) {
    historyElem.value = historyElem.value + message + "\n";   
    historyElem.scrollTop = historyElem.scrollHeight;
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
    historyElem.value = "";
  }
  
  void handleKeyPress(/* html.KeyboardEvent */ e) {
    if (NEWLINE == e.keyCode) {
      String text = shellElem.value;
      String code = text.substring(PROMPT.length);
      if (!code.isEmpty) {
        writeln(text);
        // TODO: get back errors
        interpreter.interpret(code);
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
    new JsObject(context['Glue'])
        .callMethod('hideCmEditor', [jsCodeMirrorInstance]);
    userText = editorElem.value;
    ListNode nodes;

    interpreter.interpret(userText);
    hideEditor();
  }
}
