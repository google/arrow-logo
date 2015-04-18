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
  final html.InputElement editorFileInput;
  final html.Element editorDownloadButton;
  final html.Element editorCommitButton;

  final Parser parser;
  InterpreterInterface interpreter;

  String userText;

  ConsoleImpl(this.interpreter)
      : shellElem = html.document.querySelector('#shell'),
        historyElem = html.document.querySelector('#history'),
        editorElem = html.document.querySelector('#editor'),
        editorBackground = html.document.querySelector("#editorBackground"),
        editorFileInput = html.document.querySelector('#load'),
        editorCommitButton = html.document.querySelector('#commit'),
        editorDownloadButton = html.document.querySelector('#download'),
        parser = new Parser(Primitive.makeTopLevel()) {

    editorFileInput.onChange.listen((e) => _onFileInputChange());

    shellElem.focus();
    shellElem.onKeyPress.listen(handleKeyPress);
    shellElem.onKeyDown.listen(handleKeyDown);
    editorDownloadButton.onClick.listen(handleDownloadClick);
    editorCommitButton.onClick.listen(handleCommitClick);
    writeln("Welcome to ArrowLogo.");
    writeln("Type 'help' for help.");
    writeln("Type 'edall' to switch to the editor.");
    prompt();
  }

  String getContentsAsUrl() {
    return 'data:text/csv;charset=UTF-8,${Uri.encodeQueryComponent(editorElem.value)}';
  }

  void processAction(List msg) {
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

  void _onFileInputChange() {
    var fileRef = editorFileInput.files[0];
    print(fileRef.name);
    if (fileRef.name.isEmpty) {
      return;
    }
    var reader = new html.FileReader();
    reader.onLoad.listen((e) {
      // TODO: ask before discarding user text.
      editorElem.value = reader.result;
      editorFileInput.value = "";
    });
    reader.readAsText(fileRef);
  }

  void processDefined(String defnName) {
    writeln("You defined $defnName");
  }

  void processTrace(String traceString) {
    writeln(traceString);
  }

  void processException(String exceptionString) {
    writeln(exceptionString);
  }

  void hideEditor() {
    editorBackground.classes.add('invisible');
    editorElem.classes.add('invisible');
    editorFileInput.classes.add('invisible');
    editorDownloadButton.classes.add('invisible');
    editorCommitButton.classes.add('invisible');
    shellElem.classes.remove('invisible');
    historyElem.classes.remove('invisible');
    shellElem.focus();
  }

  void showEditor() {
    editorBackground.classes.remove('invisible');
    editorElem.classes.remove('invisible');
    editorFileInput.classes.remove('invisible');
    editorDownloadButton.classes.remove('invisible');
    editorCommitButton.classes.remove('invisible');
    shellElem.classes.add('invisible');
    historyElem.classes.add('invisible');
    editorElem.focus();
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

  void handleDownloadClick(html.Event e) {
    var downloadLink = html.document.createElement("a");
    downloadLink.setAttribute("href", getContentsAsUrl());
    downloadLink.setAttribute("download", "program.logo");
    downloadLink.click();
  }

  void handleCommitClick(html.Event e) {
    userText = editorElem.value;

    interpreter.interpret(userText);
    hideEditor();
  }
}
