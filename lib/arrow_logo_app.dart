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

library arrow_logo_app;

import 'package:angular2/angular2.dart';
import 'package:angular2/di.dart';

import 'console.dart';
import 'console_impl.dart';
import 'debug.dart';
import "editor_panel.dart";
import "graphics_panel.dart";
import 'interpreter.dart';
import "turtle.dart";
import "turtle_impl.dart";

class ArrowLogoModule {
  List<Binding> get bindings => [
    TurtleWorkerImpl,
    ConsoleImpl,
    InterpreterImpl,
    SimpleDebug,
    new Binding(Debug, toValue: new SimpleDebug()),
    new Binding(TurtleWorker, toAlias: TurtleWorkerImpl),
    new Binding(Console, toAlias: ConsoleImpl),
    new Binding(InterpreterInterface, toAlias: InterpreterImpl)
  ];
}

@Component(
  selector: 'arrow-logo-app'
)
@View(
  template: '''
<style>
div#container {
  margin: 0 auto;
  height: 600px;
  width: 910px;
}

h1.title {
  font-family: 'Averia Libre', cursive;
  text-align: right;
  margin-right: 1em;
  margin-top: 1em;
}

div.main {
  position: relative;
  width: 600px;
  height: 600px;
  margin-left: 10px;
  margin-right: 10px;
}
</style>
<div id="container">
  <h1 class="title">ArrowLogo</h1>
  <div class="main">
    <graphics-panel></graphics-panel>
    <editor-panel></editor-panel>
  </div>
</div>
''',
  directives: const [EditorPanel, GraphicsPanel]
)
class ArrowLogoApp {
  Console console;
  InterpreterInterface interpreter;

  ArrowLogoApp(this.console, this.interpreter) {
    console.interpreter = interpreter.interpret;
  }
}