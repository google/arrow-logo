library arrowlogo;

import "package:arrowlogo/scope.dart";
import "package:arrowlogo/debug.dart";
import "package:arrowlogo/interpreter.dart";
import "package:arrowlogo/nodes.dart";

import "./mocks.dart";

void main() {
  Scope globalScope;
  var turtle = new MockTurtleWorker();
  var console = new MockConsole();
  var parent = new SimpleDebug();

  globalScope = new Scope(Primitive.getBuiltIns());
  InterpreterImpl interpreter = new InterpreterImpl.internal(
      globalScope, parent, turtle, console);
  var program = '''
to fib :n
if :n <= 1
[output 1]
output (fib (:n - 2)) + (fib (:n - 1))
end

fib 25
''';
  var tick = new DateTime.now().millisecondsSinceEpoch;
  interpreter.interpret(program);
  print(new DateTime.now().millisecondsSinceEpoch - tick);
}