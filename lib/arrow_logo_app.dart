// Copyright 2015 Google Inc. All Rights Reserved.
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

import 'package:angular/angular.dart';

import 'console.dart';
import 'console_impl.dart';
import 'debug.dart';
import "editor_panel.dart";
import "graphics_panel.dart";
import 'interpreter.dart';
import "turtle.dart";
import "turtle_impl.dart";

class ArrowLogoModule {
  List get;
}

@Component(selector: 'arrow-logo-app', template: '''
<div id="container">
  <h1 class="title">ArrowLogo</h1>
  <div class="main">
    <graphics-panel></graphics-panel>
    <editor-panel></editor-panel>
  </div>
</div>
''', directives: const [
  EditorPanel,
  GraphicsPanel
], providers: const [
  const ValueProvider(Debug, const SimpleDebug()),
  const ClassProvider(TurtleWorker, useClass: TurtleWorkerImpl),
  const ClassProvider(ArrowConsole, useClass: ConsoleImpl),
  const ClassProvider(InterpreterInterface, useClass: InterpreterImpl)
])
class ArrowLogoApp {
  ArrowConsole console;
  InterpreterInterface interpreter;

  ArrowLogoApp(this.console, this.interpreter) {
    console.interpreter = (text) => interpreter.interpret(text);
  }
}
