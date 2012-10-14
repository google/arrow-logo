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

class MockTurtle implements Turtle {
  
}

class MockConsole implements Console {
  
}

class InterpreterTest extends UnitTests {

  var mockTurtle;
  var mockConsole;
  Scope globalScope;
  Interpreter interpreter;

  InterpreterTest() {
    mockTurtle = new MockTurtle();
    mockConsole = new MockConsole();
    globalScope = new Scope(new Map());
    interpreter = new Interpreter(mockTurtle, mockConsole, globalScope);
  }

  void testEvalValues() {
    assertEquals(
      Primitive.UNIT, 
      interpreter.eval(ListNode.NIL));
    assertEquals(
      new NumberNode.int(1),
      interpreter.eval(ListNode.makeList([new NumberNode.int(1)])));
    assertEquals(
      ListNode.makeList([new NumberNode.int(1)]), 
      interpreter.eval(    
        ListNode.makeList([ListNode.makeList([new NumberNode.int(1)])])));
    assertEquals(
      ListNode.makeList([Primitive.FORWARD]), 
      interpreter.eval(
        ListNode.makeList([ListNode.makeList([Primitive.FORWARD])])));    
  }

  void testEvalIf() {
    Node fortyTwo = new NumberNode.int(42);
    assertEquals(
      fortyTwo,
      interpreter.eval(
        ListNode.makeList([
          Primitive.IF, Primitive.TRUE, fortyTwo])));
    assertEquals(
      Primitive.UNIT,
      interpreter.eval(
        ListNode.makeList([
          Primitive.IF, Primitive.FALSE, fortyTwo])));
    assertEquals(
      fortyTwo,
      interpreter.eval(
        ListNode.makeList([
          Primitive.IFELSE, Primitive.TRUE, fortyTwo, Primitive.PI])));
    assertEquals(
      new NumberNode.float(math.PI),
      interpreter.eval(
        ListNode.makeList([
          Primitive.IFELSE, Primitive.FALSE, fortyTwo, Primitive.PI])));
  }
  
  void run() {
    testEvalValues();
    testEvalIf();
    print("InterpreterTest ok");
  }
}
