import "package:arrowlogo/console.dart";
import "package:arrowlogo/nodes.dart";
import "package:arrowlogo/turtle.dart";

class MockConsole extends ArrowConsole {
  init(dynamic nativeElement) {}
  set interpreter(ConsoleInterpreterFn) {}
  void processAction(List raw) {}
  void processDefined(String defnName) {}
  void processTrace(String traceString) {}
  void processException(String exMessage) {}
}

class MockTurtleWorker extends TurtleWorker {

  init(userCanvas, turtleCanvas) {}

  @override
  void receive(Primitive p, List<dynamic> args) {
    // ignore
  }

  TurtleState get state => new TurtleState(0.0, 0.0, 0.0);
}
