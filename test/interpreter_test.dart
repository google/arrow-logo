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
    Node defn = new DefnNode("foo",
      ListNode.makeList([ new WordNode("\"x") ]),
      ListNode.makeList([
        Primitive.QUOTIENT,
        Primitive.THING, new WordNode("\"x"),
        new NumberNode.int(2)]));
    expect(interpreter.eval(
        ListNode.makeList([defn, new WordNode("foo"), fortyTwo])),
        equals(twentyOne));
  }
  
  void testEvalConcat() {
    Node foo = new WordNode("\"foo");
    Node bar = new WordNode("\"bar");
    Node barlist = ListNode.makeList([bar]);
    
    expect(interpreter.eval(
        ListNode.makeList([Primitive.FPUT, foo, barlist])),
        equals(ListNode.makeList([foo, bar])));

    expect(interpreter.eval(
        ListNode.makeList([Primitive.LPUT, foo, barlist])),
        equals(ListNode.makeList([bar, foo])));                               
  }
  
  void testApplyTemplate() {
    ListNode nodes = 
        ListNode.makeList([
            Primitive.APPLY, // new WordNode("optwo"),
            ListNode.makeList([
                ListNode.makeList([
                    new WordNode("x"), new WordNode("y")
                    ]),
                Primitive.SUM, 
                new WordNode("x"),
                new WordNode("y")
                ]),
            ListNode.makeList([
                new NumberNode.int(1),
                new NumberNode.int(2)
                ])
            ]);  
    expect(interpreter.eval(nodes),
        equals(new NumberNode.int(3)));
  }

  void testMakeSimple() {
    ListNode nodes = 
        ListNode.makeList([
            Primitive.MAKE, // new WordNode("optwo"),
            new WordNode("\"x"),
            new NumberNode.int(3)]);
    expect(interpreter.eval(nodes),
        equals(new NumberNode.int(3)));
    expect(globalScope["\"x"], equals(new NumberNode.int(3)));  
  }
  

  void testMakeLocal() {
    Scope topLevel = Primitive.makeTopLevel();
    ListNode nodes = new Parser(topLevel).parse("""
        to setx make \"x :x + 1 end
        to callx 
          local \"x
          make \"x 2
          setx
          make \"y :x
        end
        callx""");
    expect(interpreter.eval(nodes),
        equals(Primitive.UNIT));
    expect(globalScope["\"x"], equals(null));  
    expect(globalScope["\"y"], equals(new NumberNode.int(3)));  
  }
  
  void run() {
    group("InterpreterTest", () {
      /*test("eval values", testEvalValues);
      test("eval if", testEvalIf);
      test("eval defn", testEvalDefn);
      test("eval defn concat", testEvalConcat);
      test("apply template", testApplyTemplate);

      test("make simple", testMakeSimple);*/
      test("make local", testMakeLocal);
    });
  }
}
