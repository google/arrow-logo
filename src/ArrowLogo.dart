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

#import('dart:html', prefix: "html");

#source("Console.dart");
#source("Node.dart");
#source("Parser.dart");
#source("Primitive.dart");
#source("Scope.dart");
#source("Turtle.dart");
#source("Interpreter.dart");

class ArrowLogo {

  static final int NEWLINE = 0xD;

  static Scope makeTopLevel() {
    Map<String, Node> map = new Map();
    for (Primitive p in Primitive.commandsList) {
      map[p.name] = p;
      if (p.altName != null) {
        map[p.altName] = p;
      }
    }
    return new Scope(map);
  }

  html.Element commandInput;
  html.Element userCanvas;
  html.Element turtleCanvas;
  html.Element commandListElem;
  
  final Scope toplevel;
  Parser parser;
  Turtle turtle;
  Console console;
  Interpreter interpreter;
  
  ArrowLogo() : toplevel = makeTopLevel() {
    parser = new Parser(toplevel);
  }
      
  void run() {
    //commandInput =  html.document.query('#command_input');
    //commandInput.on.keyPress.add(handleKeyPress);
    userCanvas = html.document.query("#user_canvas");
    var userCtx = userCanvas.getContext("2d");
    turtleCanvas = html.document.query("#turtle_canvas");
    var turtleCtx = turtleCanvas.getContext("2d");
    commandListElem = html.document.query("#command_list");

    num width = Math.parseInt(userCanvas.attributes["width"]);
    num height = Math.parseInt(userCanvas.attributes["height"]);
    turtle = new Turtle(turtleCtx, userCtx, width, height);
    turtle.draw();
    var consoleElem = html.document.query('#console');
    consoleElem.focus();
    console = new Console(consoleElem, parser);
    interpreter = new Interpreter(turtle, console, toplevel.extend());
    console.init(interpreter);
  }
  
  String removeLastCommand(String code) {
    int len = code.length - 1;
    if (len <= 0) {
      return "";
    }
    code = code.substring(0, len);
    return code.substring(0, code.lastIndexOf("\n"));
  }

  void handleKeyPress(html.KeyboardEvent e) {
    if (NEWLINE == e.keyCode) {
      String text = commandInput.value;
      commandInput.value = "";
      var code = commandListElem.value;
      if (text == ":undo") {  // TODO: proper code editing UI? replay?
        commandListElem.value = removeLastCommand(code);
        // TODO: also undo the action!
      } else if (text.length > 0) {
        Node node = parser.parse(text);
        print("nodes : ${node}");
        interpreter.eval(node);
        commandListElem.value = code + text + "\n";
      }
    }
  }
}

void main() {
  new ArrowLogo().run();
}
