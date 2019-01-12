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
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import "dart:math" as math;

import "package:arrowlogo/console.dart";
import "package:arrowlogo/debug.dart";
import "package:arrowlogo/interpreter.dart";
import "package:arrowlogo/nodes.dart";
import "package:arrowlogo/parser.dart";
import "package:arrowlogo/scope.dart";
import "package:arrowlogo/turtle.dart";

class MockConsole extends Mock implements ArrowConsole {}
class MockTurtleWorker extends Mock implements TurtleWorker {}

void main() {
  Scope globalScope;
  final turtle = new MockTurtleWorker();
  final console = new MockConsole();
  final parent = new SimpleDebug();
  InterpreterImpl interpreter;

  InterpreterImpl makeInterpreter([Map<String, Node> map = null]) {
    globalScope = new Scope(map == null ? new Map() : map);
    interpreter = new InterpreterImpl.internal(
        globalScope, parent, turtle, console);
    return interpreter;
  }

    group("InterpreterTest", () {
      test("eval values", () {
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
      });
      test("eval if", () {
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
          equals(new NumberNode.float(math.pi)));
      });
      test("eval defn", () {
        makeInterpreter();
        final fortyTwo = new NumberNode.int(42);
        final twentyOne = new NumberNode.int(21);
        final defn = new DefnNode("foo",
          ListNode.makeList([ new WordNode("x") ]),
          ListNode.makeList([
            Primitive.QUOTIENT,
            Primitive.THING, Primitive.QUOTE, new WordNode("x"),
            new NumberNode.int(2)]));
        interpreter.define(defn);
        expect(interpreter.evalSequence(
            ListNode.makeList([new WordNode("foo"), fortyTwo])),
            equals(twentyOne));
      });
      test("eval make update", () {
        final fortyTwo = new NumberNode.int(42);
        final varMap = <String, Node>{};
        varMap["x"] = fortyTwo;
        makeInterpreter(varMap);
        final seq = ListNode.makeList([
            Primitive.MAKE,
            Primitive.QUOTE, new WordNode("x"),
            Primitive.SUM,
                Primitive.THING, Primitive.QUOTE, new WordNode("x"),
                new NumberNode.int(1)]);
          expect(interpreter.evalSequence(seq), equals(Primitive.UNIT));
          expect(interpreter.globalScope["x"], equals(new NumberNode.int(43)));
      });
      test("eval make deref", () {
        final fortyTwo = new NumberNode.int(42);
        final varMap = <String, Node>{};
        varMap["x"] = fortyTwo;
        varMap["y"] = new WordNode("x");
        makeInterpreter(varMap);
        final seq = ListNode.makeList([
            Primitive.MAKE,
            Primitive.THING, Primitive.QUOTE, new WordNode("y"),
            Primitive.SUM,
                Primitive.THING, Primitive.THING, Primitive.QUOTE, new WordNode("y"),
                new NumberNode.int(1)]);
          expect(interpreter.evalSequence(seq), equals(Primitive.UNIT));
          expect(interpreter.globalScope["x"], equals(new NumberNode.int(43)));
      });
      test("eval make deref var", () {
        final fortyTwo = new NumberNode.int(42);
        final varMap = <String, Node>{};
        varMap["x"] = fortyTwo;
        makeInterpreter(varMap);
        final seq = ListNode.makeList([
            Primitive.MAKE,
            Primitive.QUOTE, new WordNode("y"),
            Primitive.QUOTE, new WordNode("x"),
            Primitive.MAKE,
            Primitive.THING, Primitive.QUOTE, new WordNode("y"),
            Primitive.SUM,
                Primitive.THING, Primitive.THING, Primitive.QUOTE, new WordNode("y"),
                new NumberNode.int(1)]);
          expect(interpreter.evalSequence(seq), equals(Primitive.UNIT));
          expect(interpreter.globalScope["x"], equals(new NumberNode.int(43)));
      });
      test("eval defn concat", () {
        makeInterpreter();

        final foo = new WordNode("foo");
        final bar = new WordNode("bar");
        final barlist = ListNode.makeList([bar]);

        expect(interpreter.evalSequence(
            ListNode.makeList([Primitive.FPUT, Primitive.QUOTE, foo, barlist])),
            equals(ListNode.makeList([foo, bar])));

        expect(interpreter.evalSequence(
            ListNode.makeList([Primitive.LPUT, Primitive.QUOTE, foo, barlist])),
            equals(ListNode.makeList([bar, foo])));
      });
      test("eval op", () {
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
        expect(
            interpreter.evalSequence(
                ListNode.makeList([
                  Primitive.EQUALS,
                  Primitive.FALSE,
                  Primitive.FALSE
                ])),
            equals(Primitive.TRUE));
      });
      test("eval first butfirst", () {
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
      });
      test("apply template", () {
        makeInterpreter();

        final nodes =
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
      });
      test("item", () {
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
      });
      test("make simple", () {
        makeInterpreter();

        final nodes =
            ListNode.makeList([
                Primitive.MAKE,
                Primitive.QUOTE,
                new WordNode("x"),
                new NumberNode.int(3)]);
        expect(
            interpreter.evalSequence(nodes),
            equals(Primitive.UNIT));
        expect(globalScope["x"], equals(new NumberNode.int(3)));
      });
      test("make local", () {
        makeInterpreter();

        final nodes = new Parser(Primitive.makeTopLevel()).parse("""
        to setx make \"x :x + 1 end
        to callx 
          local \"x
          make \"x 2
          setx
          make \"y :x
        end""");
        for (final defn in nodes) {
          interpreter.define(defn);
        }
        expect(interpreter.evalSequence(
            new ListNode.cons(new WordNode("callx"), new ListNode.nil())),
            equals(Primitive.UNIT));
        expect(globalScope["x"], equals(null));
        expect(globalScope["y"], equals(new NumberNode.int(3)));
      });
    });
}

