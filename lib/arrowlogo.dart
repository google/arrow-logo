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
library arrowlogo;

import 'package:persistent/persistent.dart';
import 'package:pattern_matching/pattern_matching.dart';

import 'dart:html' as html;
import 'dart:math' as math;

part "console.dart";
part "interpreter.dart";
part "node.dart";
part "parser.dart";
part "primitive.dart";
part "scope.dart";
part "turtle.dart";

class ArrowLogo {
  
  html.CanvasElement userCanvas;
  html.CanvasElement turtleCanvas;
  html.TextAreaElement commandListElem;
  
  final Scope toplevel;
  Parser parser;
  Turtle turtle;
  Console console;
  Interpreter interpreter;
  
  ArrowLogo() : toplevel = Primitive.makeTopLevel() {
    parser = new Parser(toplevel);
  }
      
  static num getNum(String sizePx) {
    String size = sizePx.substring(0, sizePx.length - 2);
    return math.parseInt(size);
  }
  
  void run() {
    userCanvas = html.document.query("#user");
    var userCtx = userCanvas.getContext("2d");
    turtleCanvas = html.document.query("#turtle");
    var turtleCtx = turtleCanvas.getContext("2d");

    var shellElem = html.document.query('#shell');
    var historyElem = html.document.query('#history');
    var editorElem = html.document.query('#editor');
    var editorCommitButton = html.document.query('#commit');
    shellElem.focus();
    console = new Console(shellElem, historyElem, editorElem,
        editorCommitButton, parser);

    userCanvas.computedStyle.then((value) {
      html.CSSStyleDeclaration style = value;
      num width = getNum(style.width);
      num height = getNum(style.height);
      
      turtle = new Turtle(turtleCtx, userCtx, width, height);
      turtle.draw();
      interpreter = new Interpreter(turtle, console, toplevel.extend());
      console.init(interpreter);
    });
  }
}

void main() {
  new ArrowLogo().run();
}
