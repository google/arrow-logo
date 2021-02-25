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

import 'dart:html' as html;

import 'console.dart';
import 'nodes.dart';
import 'parser.dart';

class ConsoleImpl extends ArrowConsole {
  static final int NEWLINE = 0xD;
  static final int LEFT = 37;
  static final String PROMPT = "?";

  html.TextAreaElement shellElem;
  html.TextAreaElement historyElem;
  html.Element editorElem;
  html.Element editorBackground;
  html.InputElement editorFileInput;
  html.Element editorDownloadButton;
  html.Element editorRunButton;
  html.Element editorCloseButton;
  Parser parser;

  String userText = "";

  ConsoleImpl() : parser = new Parser(Primitive.makeTopLevel());

  init(dynamic dynElement) {
    html.Element element = dynElement;
    shellElem = element.querySelector('#shell');
    historyElem = element.querySelector('#history');
    editorElem = element.querySelector('#editor');
    editorFileInput = element.querySelector('#load');
    editorRunButton = element.querySelector('#run');
    editorCloseButton = element.querySelector('#close');
    editorDownloadButton = element.querySelector('#download');

    editorFileInput.onChange.listen((e) => _onFileInputChange());

    shellElem.focus();
    shellElem.onKeyPress.listen(shellHandleKeyPress);
    shellElem.onKeyDown.listen(shellHandleKeyDown);
    editorDownloadButton.onClick.listen(editorHandleDownload);
    editorRunButton.onClick.listen(editorHandleRun);
    editorCloseButton.onClick.listen(editorHandleClose);
    writeln("Welcome to ArrowLogo.");
    writeln("Type 'help' for help.");
    writeln("Type 'edall' to switch to the editor.");
    prompt();
  }

  ConsoleInterpreterFn _interpret;
  set interpreter(ConsoleInterpreterFn doInterpret) {
    _interpret = doInterpret;
  }

  String get editorContent => extractTextPreserveWhitespace(editorElem);

  set editorContent(String newContent) => editorElem.setInnerHtml(newContent);

  String getContentsAsUrl() {
    return 'data:text/csv;charset=UTF-8,${Uri.encodeQueryComponent(editorContent)}';
  }

  void processAction(List msg) {
    final p = Primitive.lookup(msg[0]);
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

  // TODO: revive load functionality.
  void _onFileInputChange() {
    final fileRef = editorFileInput.files[0];
    print(fileRef.name);
    if (fileRef.name.isEmpty) {
      return;
    }
    final reader = new html.FileReader();
    reader.onLoad.listen((e) {
      // TODO: ask before discarding user text.
      editorContent = reader.result;
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
    editorElem.classes.add('invisible');
    editorFileInput.classes.add('invisible');
    editorDownloadButton.classes.add('invisible');
    editorRunButton.classes.add('invisible');
    editorCloseButton.classes.add('invisible');
    shellElem.classes.remove('invisible');
    historyElem.classes.remove('invisible');
    shellElem.focus();
  }

  void showEditor() {
    editorElem.classes.remove('invisible');
    editorFileInput.classes.remove('invisible');
    editorDownloadButton.classes.remove('invisible');
    editorRunButton.classes.remove('invisible');
    editorCloseButton.classes.remove('invisible');
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
    for (final p in Primitive.commandsList) {
      writeln(p.name + (p.altName != null ? "  ${p.altName}" : ""));
    }
    writeln("  supported operators:");
    for (final p in Primitive.operatorList) {
      writeln(p.name + (p.altName != null ? "  ${p.altName}" : ""));
    }
  }

  void clearText() {
    historyElem.value = "";
  }

  void shellHandleKeyPress(html.KeyboardEvent e) {
    if (NEWLINE == e.keyCode) {
      final text = shellElem.value;
      final code = text.substring(PROMPT.length);
      if (!code.isEmpty) {
        writeln(text);
        // TODO: get back errors
        _interpret(code);
      }
      e.preventDefault();
      prompt();
    }
  }

  /**
   *  Ensure the cursor does not move into the prompt.
   */
  void shellHandleKeyDown(html.KeyboardEvent e) {
    if (LEFT == e.keyCode &&
        shellElem.selectionStart == PROMPT.length &&
        shellElem.selectionEnd == PROMPT.length) {
      e.preventDefault();
    }
  }

  void editorHandleDownload(html.Event e) {
    final downloadLink = html.document.createElement("a");
    downloadLink.setAttribute("href", getContentsAsUrl());
    downloadLink.setAttribute("download", "program.logo");
    downloadLink.click();
  }

  void editorHandleClose(html.Event e) {
    hideEditor();
  }

  void editorHandleRun(html.Event e) {
    userText = editorContent;
    _interpret(userText);
  }

  static String extractTextPreserveWhitespace(html.Node node) {
    switch (node.nodeType) {
      case html.Node.ELEMENT_NODE:
        var res = " ";
        // This assumes that ;-comments are wrapped in a single node.
        for (var child in node.childNodes) {
          res += extractTextPreserveWhitespace(child) + "\n";
        }
        return res;
      case html.Node.TEXT_NODE:
        return (node as html.Text).wholeText;
      default:
        throw new Exception(
          "not implemented: ${node.nodeType}",
        );
    }
  }
}
