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

import 'dart:html' as html;
import 'dart:isolate' as isolate;
import 'dart:math' as math;

import "console.dart";
import 'interpreter.dart';
import 'nodes.dart';
import 'parser.dart';
import "scope.dart";
import "turtle.dart";

class ArrowLogo {
  
  final isolate.ReceivePort debugPort;
  final isolate.ReceivePort consolePort;
  final isolate.ReceivePort turtlePort;
  final isolate.SendPort interpreterPort;
 
  TurtleWorker turtleWorker;
  Console console;
  
  ArrowLogo() 
      : debugPort = new isolate.ReceivePort(),
        consolePort = new isolate.ReceivePort(),
        turtlePort = new isolate.ReceivePort(),
        interpreterPort = isolate.spawnFunction(interpreterTopLevel) {
    turtleWorker = new TurtleWorker();
    console = new Console(interpreterPort);
  }
  
  void run() {
    debugPort.receive((msg, _) {
      print(msg);
    });
    
    interpreterPort.send([INIT, debugPort.toSendPort(),
        turtlePort.toSendPort(), consolePort.toSendPort()]);
    consolePort.receive(console.receiveFun);   
    turtlePort.receive(turtleWorker.receive);
  }
}

void main() {
  new ArrowLogo().run();
}

const String INIT = "init";

void interpreterTopLevel() {
  isolate.port.receive((msg, replyPort) {
    if (msg[0] == INIT) {
      interpreterWorker = new InterpreterWorker(msg[1], msg[2], msg[3]);
      return;
    } 
    interpreterWorker.interpret(msg[0]);
  });
}