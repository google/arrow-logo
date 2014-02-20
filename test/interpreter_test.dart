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
library interpreter_test;

import 'package:unittest/unittest.dart';

import "dart:math" as math;

import "package:arrowlogo/interpreter.dart";
import "package:arrowlogo/nodes.dart";
import "package:arrowlogo/parser.dart";
import "package:arrowlogo/scope.dart";

class MockConsole {
  void receive(dynamic raw) {}
}

class InterpreterTest {

  Scope globalScope;
  var turtle = new Object();
  var console = new MockConsole();
  var parent = new Object();
  InterpreterImpl interpreter;

  InterpreterImpl makeInterpreter() {
    globalScope = new Scope(new Map());
    interpreter = new InterpreterImpl.internal(
        globalScope, parent, turtle, console);
    return interpreter;
  }
  
  InterpreterTest() {
  }

  void testEvalValues() {
    makeInterpreter();
    expect(       
      interpreter.evalSequence(ListNode.NIL),
      equals(Primitive.UNIT));
    expect(
      interpreter.evalSequence(ListNode.makeList([new NumberNode.int(1)])),
      equals(new NumberNode.int(1)));
    expect(
      interpreter.evalSequence(    
        ListNode.makeList([ListNode.makeList([new NumberNode.int(1)])])),
      equals(ListNode.makeList([new NumberNode.int(1)])));
    expect(
      interpreter.evalSequence(
        ListNode.makeList([ListNode.makeList([Primitive.FORWARD])])),
      equals(ListNode.makeList([Primitive.FORWARD])));    
  }

  void testEvalIf() {
    makeInterpreter();
    Node fortyTwo = new NumberNode.int(42);
    expect(
      interpreter.evalSequence(
        ListNode.makeList([
          Primitive.IF, Primitive.TRUE, fortyTwo])),
      equals(fortyTwo));
    expect(
      interpreter.evalSequence(
        ListNode.makeList([
          Primitive.IF, Primitive.FALSE, fortyTwo])),
      equals(Primitive.UNIT));
    expect(
      interpreter.evalSequence(
        ListNode.makeList([
          Primitive.IFELSE, Primitive.TRUE, fortyTwo, Primitive.PI])),
      equals(fortyTwo));
    expect(
      interpreter.evalSequence(
        ListNode.makeList([
          Primitive.IFELSE, Primitive.FALSE, fortyTwo, Primitive.PI])),
      equals(new NumberNode.float(math.PI)));
  }
  
  void testEvalDefn() {
    makeInterpreter();
    Node fortyTwo = new NumberNode.int(42);
    Node twentyOne = new NumberNode.int(21);
    Node defn = new DefnNode("foo",
      ListNode.makeList([ new WordNode("x") ]),
      ListNode.makeList([
        Primitive.QUOTIENT,
        Primitive.THING, Primitive.QUOTE, new WordNode("x"),
        new NumberNode.int(2)]));
    interpreter.define(defn);
    expect(interpreter.evalSequence(
        ListNode.makeList([new WordNode("foo"), fortyTwo])),
        equals(twentyOne));
  }
  
  void testEvalConcat() {
    makeInterpreter();

    Node foo = new WordNode("foo");
    Node bar = new WordNode("bar");
    Node barlist = ListNode.makeList([bar]);
    
    expect(interpreter.evalSequence(
        ListNode.makeList([Primitive.FPUT, Primitive.QUOTE, foo, barlist])),
        equals(ListNode.makeList([foo, bar])));

    expect(interpreter.evalSequence(
        ListNode.makeList([Primitive.LPUT, Primitive.QUOTE, foo, barlist])),
        equals(ListNode.makeList([bar, foo])));                               
  }
  
  void testEvalOp() {
    makeInterpreter();

    expect(
      interpreter.evalSequence(
        ListNode.makeList([
            Primitive.SUM,
            new NumberNode.int(2),
            new NumberNode.int(2)
        ])),
      equals(new NumberNode.int(4)));
    expect(
      interpreter.evalSequence(
        ListNode.makeList([
            Primitive.DIFFERENCE,
            new NumberNode.int(2),
            new NumberNode.float(5.3)
        ])),
      equals(new NumberNode.float(-3.3)));
    expect(
      interpreter.evalSequence(
        ListNode.makeList([
            Primitive.PRODUCT,
            new NumberNode.int(3),
            new NumberNode.float(3.0)
        ])),
      equals(new NumberNode.float(9.0)));
    expect(
      interpreter.evalSequence(
        ListNode.makeList([
            Primitive.QUOTIENT,
            new NumberNode.int(10),
            new NumberNode.int(3)
        ])),
      equals(new NumberNode.int(3)));
    expect(
          interpreter.evalSequence(
            ListNode.makeList([
                Primitive.QUOTIENT,
                new NumberNode.float(9.0),
                new NumberNode.int(3)
            ])),
          equals(new NumberNode.float(3.0)));
    expect(
          interpreter.evalSequence(
            ListNode.makeList([
                Primitive.REMAINDER,
                new NumberNode.float(19.0),
                new NumberNode.int(3)
            ])),
          equals(new NumberNode.float(1.0)));
    expect(
          interpreter.evalSequence(
            ListNode.makeList([
                Primitive.EQUALS,
                new NumberNode.float(19.0),
                new NumberNode.float(19.0)
            ])),
          equals(Primitive.TRUE));
  }
  
  void testEvalFirstButFirst() {
    makeInterpreter();

    expect(
          interpreter.evalSequence(
            ListNode.makeList([
                Primitive.FIRST,
                Primitive.QUOTE,
                new WordNode("abc")
            ])),
          equals(new WordNode("a")));

    expect(
          interpreter.evalSequence(
            ListNode.makeList([
                Primitive.FIRST,
                Primitive.QUOTE,
                ListNode.makeList([new WordNode("abc")])
            ])),
          equals(new WordNode("abc")));

    expect(
          interpreter.evalSequence(
            ListNode.makeList([
                Primitive.BUTFIRST,
                Primitive.QUOTE,
                new WordNode("abc")
            ])),
          equals(new WordNode("bc")));

    expect(
          interpreter.evalSequence(
            ListNode.makeList([
                Primitive.BUTFIRST,
                ListNode.makeList([new WordNode("abc")])
            ])),
          equals(ListNode.NIL));
  }

  void testApplyTemplate() {
    makeInterpreter();

    ListNode nodes = 
        ListNode.makeList([
            Primitive.APPLY,
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
    expect(interpreter.evalSequence(nodes),
        equals(new NumberNode.int(3)));
  }

  void testItem() {
      makeInterpreter();

      ListNode nodes = 
          ListNode.makeList([
              Primitive.ITEM,
              new NumberNode.int(3),
              Primitive.QUOTE,
              new WordNode("abcx"),
              ]);
      expect(
          interpreter.evalSequence(nodes),
          equals(new WordNode("c")));
      
      nodes = 
          ListNode.makeList([
              Primitive.ITEM,
              new NumberNode.int(3),
              ListNode.makeList([
                new WordNode("a"),
                new WordNode("b"),
                new WordNode("c"),
              ])]);
      expect(
          interpreter.evalSequence(nodes),
          equals(new WordNode("c")));
  }
  
  void testMakeSimple() {
    makeInterpreter();

    ListNode nodes = 
        ListNode.makeList([
            Primitive.MAKE,
            Primitive.QUOTE,
            new WordNode("x"),
            new NumberNode.int(3)]);
    expect(
        interpreter.evalSequence(nodes),
        equals(Primitive.UNIT));
    expect(globalScope["x"], equals(new NumberNode.int(3)));
  }
  
  void testMakeLocal() {
    makeInterpreter();

    ListNode nodes = new Parser(Primitive.makeTopLevel()).parse("""
        to setx make \"x :x + 1 end
        to callx 
          local \"x
          make \"x 2
          setx
          make \"y :x
        end""");
    for (Node defn in nodes) {
      print("define ${defn}");
      interpreter.define(defn);
    }
    expect(interpreter.evalSequence(
        new ListNode.cons(new WordNode("callx"), new ListNode.nil())),
        equals(Primitive.UNIT));
    expect(globalScope["x"], equals(null));
    expect(globalScope["y"], equals(new NumberNode.int(3)));
  }
  
  void run() {
    group("InterpreterTest", () {
      test("eval values", testEvalValues);
      test("eval if", testEvalIf);
      test("eval defn", testEvalDefn);
      test("eval defn concat", testEvalConcat);
      test("eval op", testEvalOp);
      test("eval first butfirst", testEvalFirstButFirst);
      test("apply template", testApplyTemplate);
      test("item", testItem);
      test("make simple", testMakeSimple);
      test("make local", testMakeLocal);
    });
  }
}
