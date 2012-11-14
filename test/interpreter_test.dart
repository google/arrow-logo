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
part of arrowlogo;

class MockTurtle implements Turtle {
  
}

class MockConsole implements Console {
  
}

class InterpreterTest {

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
    expect(       
      interpreter.eval(ListNode.NIL),
      equals(Primitive.UNIT));
    expect(
      interpreter.eval(ListNode.makeList([new NumberNode.int(1)])),
      equals(new NumberNode.int(1)));
    expect(
      interpreter.eval(    
        ListNode.makeList([ListNode.makeList([new NumberNode.int(1)])])),
      equals(ListNode.makeList([new NumberNode.int(1)])));
    expect(
      interpreter.eval(
        ListNode.makeList([ListNode.makeList([Primitive.FORWARD])])),
      equals(ListNode.makeList([Primitive.FORWARD])));    
  }

  void testEvalIf() {
    Node fortyTwo = new NumberNode.int(42);
    expect(
      interpreter.eval(
        ListNode.makeList([
          Primitive.IF, Primitive.TRUE, fortyTwo])),
      equals(fortyTwo));
    expect(
      interpreter.eval(
        ListNode.makeList([
          Primitive.IF, Primitive.FALSE, fortyTwo])),
      equals(Primitive.UNIT));
    expect(
      interpreter.eval(
        ListNode.makeList([
          Primitive.IFELSE, Primitive.TRUE, fortyTwo, Primitive.PI])),
      equals(fortyTwo));
    expect(
      interpreter.eval(
        ListNode.makeList([
          Primitive.IFELSE, Primitive.FALSE, fortyTwo, Primitive.PI])),
      equals(new NumberNode.float(math.PI)));
  }
  
  void testEvalDefn() {
    Node fortyTwo = new NumberNode.int(42);
    Node twentyOne = new NumberNode.int(21);
    Node defn = new DefnNode("foo", 1,
      ListNode.makeList([
        new WordNode(":x"), 
        Primitive.QUOTIENT, new WordNode(":x"), new NumberNode.int(2)]));
    expect(interpreter.eval(
        ListNode.makeList([defn, new WordNode("foo"), fortyTwo])),
        equals(twentyOne));
  }
  
  void run() {
    group("InterpreterTest", () {
      test("eval values", testEvalValues);
      test("eval if", testEvalIf);
      test("eval defn", testEvalDefn);
    });
  }
}
