library arrowlogo;

import "package:arrowlogo/scope.dart";
import "package:arrowlogo/debug.dart";
import "package:arrowlogo/interpreter.dart";
import "package:arrowlogo/nodes.dart";

import "./mocks.dart";

void main() {
  Scope globalScope;
  final turtle = new MockTurtleWorker();
  final console = new MockConsole();
  final parent = new SimpleDebug();

  globalScope = new Scope(Primitive.getBuiltIns());
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
