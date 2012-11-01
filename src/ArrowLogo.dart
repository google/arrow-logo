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
import 'dart:math' as math;

part "Console.dart";
part "Node.dart";
part "Parser.dart";
part "Primitive.dart";
part "Scope.dart";
part "Turtle.dart";
part "Interpreter.dart";

class ArrowLogo {

  static final int NEWLINE = 0xD;

  static Scope makeTopLevel() {
    Map<String, Node> map = new Map();
    for (String k in Primitive.getBuiltIns().keys) {
      map[k] = Primitive.getBuiltIns()[k];
    }
    return new Scope(map);
  }

  html.CanvasElement userCanvas;
  html.CanvasElement turtleCanvas;
  html.TextAreaElement commandListElem;
  
  final Scope toplevel;
  Parser parser;
  Turtle turtle;
  Console console;
  Interpreter interpreter;
  
  ArrowLogo() : toplevel = makeTopLevel() {
    parser = new Parser(toplevel);
  }
      
  void run() {
    userCanvas = html.document.query("#user_canvas");
    var userCtx = userCanvas.getContext("2d");
    turtleCanvas = html.document.query("#turtle_canvas");
    var turtleCtx = turtleCanvas.getContext("2d");
    commandListElem = html.document.query("#command_list");

    num width = math.parseInt(userCanvas.attributes["width"]);
    num height = math.parseInt(userCanvas.attributes["height"]);
    turtle = new Turtle(turtleCtx, userCtx, width, height);
    turtle.draw();
    var consoleElem = html.document.query('#console');
    consoleElem.focus();
    console = new Console(consoleElem, parser);
    interpreter = new Interpreter(turtle, console, toplevel.extend());
    console.init(interpreter);
  }
}

void main() {
  new ArrowLogo().run();
}
