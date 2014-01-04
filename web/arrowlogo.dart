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

import 'package:arrowlogo/console.dart';
import 'package:arrowlogo/console_impl.dart';
import 'package:arrowlogo/debug.dart';
import 'package:arrowlogo/interpreter.dart';
import "package:arrowlogo/turtle.dart";
import "package:arrowlogo/turtle_impl.dart";

class ArrowLogo {
  
  Debug debug;
  TurtleWorker turtle;
  Console console;
  InterpreterProxy interpreterProxy;
  InterpreterInterface interpreter;
   
  ArrowLogo() {
    debug = new SimpleDebug();
    turtle = new TurtleWorkerImpl();
    interpreterProxy = new InterpreterProxy();
    console = new ConsoleImpl(interpreterProxy);
    interpreter = new InterpreterImpl(debug, turtle, console);
  }
  
  void run() {
    interpreterProxy.init(interpreter);
  }
}

void main() {
  new ArrowLogo().run();
}
