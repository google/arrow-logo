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
import 'package:mockito/mockito.dart';

import "package:arrowlogo/console.dart";
import "package:arrowlogo/scope.dart";
import "package:arrowlogo/debug.dart";
import "package:arrowlogo/interpreter.dart";
import "package:arrowlogo/nodes.dart";
import "package:arrowlogo/turtle.dart";

class MockConsole extends Mock implements ArrowConsole {}
class MockTurtleWorker extends Mock implements TurtleWorker {}

Map<String, Node> getBuiltins() {
  var map = <String, Node>{};
  map.addAll(Primitive.getBuiltIns());
  return map;
}

void main() {
  Scope globalScope;
  final turtle = new MockTurtleWorker();
  final console = new MockConsole();
  final parent = new SimpleDebug();

  globalScope = new Scope(getBuiltins());
  InterpreterImpl interpreter = new InterpreterImpl.internal(
      globalScope, parent, turtle, console);
  final program = '''
to fib :n
if :n <= 1
[output 1]
output (fib (:n - 2)) + (fib (:n - 1))
end

fib 25
''';
  final tick = new DateTime.now().millisecondsSinceEpoch;
  interpreter.interpret(program);
  print(new DateTime.now().millisecondsSinceEpoch - tick);
}
