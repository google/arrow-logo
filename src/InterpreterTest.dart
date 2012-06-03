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

class MockTurtle {
  
}

class MockConsole {
  
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
      interpreter.eval(ListNode.makeNil()));
    assertEquals(
      WordNode.makeInt(1),
      interpreter.eval(ListNode.makeList([WordNode.makeInt(1)])));
    assertEquals(
      ListNode.makeList([WordNode.makeInt(1)]), 
      interpreter.eval(    
        ListNode.makeList([ListNode.makeList([WordNode.makeInt(1)])])));
    assertEquals(
      ListNode.makeList([Primitive.FORWARD]), 
      interpreter.eval(
        ListNode.makeList([ListNode.makeList([Primitive.FORWARD])])));    
  }
  
  void run() {
    testEvalValues();
    print("InterpreterTest ok");
  }
}
