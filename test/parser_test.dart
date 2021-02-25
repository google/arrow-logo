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

import "package:arrowlogo/nodes.dart";
import "package:arrowlogo/parser.dart";

class ParserTest {

  final Parser parser;
  
  ParserTest() 
      : parser = new Parser(Primitive.getBuiltIns());
  
  void expectAdvanceWhileConsumes(input, bool func(dynamic), prefix) {
    parser.initialize(input);
    expect(parser.advanceWhile(func), equals(prefix.length));
  }

  void run() {
    group("ParserTest", () {
      test("advance while", () {
        expectAdvanceWhileConsumes("  a", Scanner.isSpace, "  ");
        expectAdvanceWhileConsumes("a", Scanner.isSpace, "");
        expectAdvanceWhileConsumes("abc", Scanner.isAlpha, "abc");
        expectAdvanceWhileConsumes("12abc", Scanner.isDigit, "12");
        expectAdvanceWhileConsumes(".2a", Scanner.isDigitOrDot, ".2");
      });
      test("skip comment", () {
        parser.initialize(";123\n1");
        parser.nextToken();

        expect(parser.token.kind, equals(Token.TOKEN_NUM));    
        expect(parser.token.node.isNum, true);
      });
      test("tokenize num", () {
        parser.initialize("1");
        parser.tokenizeNum();
        expect(parser.pos, equals("1".length));
        expect(parser.token.kind, equals(Token.TOKEN_NUM));    
        expect(parser.token.node.isNum, true);
        Node n = parser.token.node;
        expect(n.isNum, true);
        NumberNode numInt = n;
        expect(numInt.isInt, true);
        expect(1, numInt.intValue);

        parser.initialize("1.2x");
        parser.tokenizeNum();
        expect(parser.pos, equals("1.2".length));
        expect(parser.token.kind, equals(Token.TOKEN_NUM));
        expect(parser.token.node.isNum, true);
        n = parser.token.node;
        expect(n.isNum, true);
        NumberNode numFloat = n;
        expect(numFloat.isFloat, true);
        expect(1.2, numFloat.floatValue);
        
        parser.initialize(".7");
        parser.tokenizeNum();
        n = parser.token.node;
        expect(n.isNum, true);
        numFloat = n;
        expect(numFloat.isFloat, true);
        expect(.7, numFloat.floatValue);
      });
      test("tokenize word or keyword", () {
        parser.initialize("fd");
        parser.tokenizeWord();
        expect(parser.pos, equals("fd".length));
        expect(parser.token.kind, equals(Token.TOKEN_PRIM));
        expect(parser.token.node, equals(Primitive.FORWARD));

        parser.initialize("x");
        parser.tokenizeWord();
        expect(parser.pos, equals("x".length));
        expect(Token.TOKEN_WORD, parser.token.kind);
        WordNode wn = parser.token.node;
        expect(wn.stringValue, equals("x"));
      });
      test("parse some words and numbers", () {
        expect(new NumberNode.int(1), equals(new NumberNode.int(1)));  // sanity
        expect(
          parser.parse("fd 1 fd 1.2 \"baz :math # atan \"100 ; comment\n"),
          equals(ListNode.makeList([
            Primitive.FORWARD, new NumberNode.int(1),
            Primitive.FORWARD, new NumberNode.float(1.2),
            Primitive.QUOTE, new WordNode("baz"),
            Primitive.SELECT, Primitive.THING, Primitive.QUOTE, new WordNode("math"), new WordNode("atan"),
            Primitive.QUOTE, new NumberNode.int(100)])
          ));
      });
      test("parse some lists", () {
        expect(
          parser.parse("[]"),
          equals(ListNode.makeList([ListNode.NIL])));
        expect(
          parser.parse("[1 \n ]"),
          equals(ListNode.makeList([ListNode.makeList([new NumberNode.int(1)])])));
        expect(
          parser.parse("pr [ ; comment \n 1 [ 1.2 ] [] fd 2 ]"),
          equals(ListNode.makeList([
            Primitive.PRINT,
            ListNode.makeList([
              new NumberNode.int(1), 
              ListNode.makeList([new NumberNode.float(1.2)]), 
              ListNode.NIL,
              Primitive.FORWARD,
              new NumberNode.int(2)])])
          ));
      });
      test("parse some defns", () {
        expect(
          parser.parse("to box1"),
          equals(ListNode.makeList(
            [new WordNode("INCOMPLETE_DEFINITION"),
             new WordNode("box1")])
          ));
        expect(
          parser.parse("to box end"),
          equals(ListNode.makeList(
            [new DefnNode("box", ListNode.NIL, ListNode.NIL)])
          ));
        expect(
          parser.parse("to box fd 10 end"),
          equals(ListNode.makeList([
            new DefnNode("box", ListNode.NIL, ListNode.makeList([
              Primitive.FORWARD, new NumberNode.int(10)]))])
          ));
        expect(
          parser.parse("to box :size fd :size end"),
          equals(ListNode.makeList([
            new DefnNode("box",
              ListNode.makeList([new WordNode("size")]),
              ListNode.makeList([
                Primitive.FORWARD,
                Primitive.THING,
                Primitive.QUOTE, new WordNode("size")]))])
          ));
      });
      test("parse infix expr", () {

    expect(
      parser.parse("2"),
      equals(ListNode.makeList([new NumberNode.int(2)])));
    
    expect(
      parser.parse("2 + 2"),
      equals(ListNode.makeList([
        Primitive.SUM,
          new NumberNode.int(2), 
          new NumberNode.int(2)])
      ));
    expect(
      parser.parse("2 + 2 + 2"),
      equals(ListNode.makeList([
        Primitive.SUM, 
          Primitive.SUM, 
            new NumberNode.int(2), 
            new NumberNode.int(2), 
          new NumberNode.int(2)])
      ));
    expect(
      parser.parse("2 + 3 * 4"),
      equals(ListNode.makeList([
        Primitive.SUM, 
          new NumberNode.int(2), 
          Primitive.PRODUCT, 
            new NumberNode.int(3), 
            new NumberNode.int(4)])
      ));
    expect(
      parser.parse("3 * 4 + 2"),
      equals(ListNode.makeList([
        Primitive.SUM, 
        Primitive.PRODUCT, 
          new NumberNode.int(3), 
          new NumberNode.int(4),
        new NumberNode.int(2)])));
    expect(
            parser.parse("\"x + 1"),
            equals(ListNode.makeList([
                                      Primitive.SUM,
                                      Primitive.QUOTE, new WordNode("x"),
                                      new NumberNode.int(1)])));
    expect(
        parser.parse(":x*.7"),
        equals(ListNode.makeList([ 
                                  Primitive.PRODUCT, 
                                  Primitive.THING,
                                      Primitive.QUOTE, new WordNode("x"),
                                  new NumberNode.float(.7)])));
    expect(
      parser.parse("2^3.5^(7+1) / 3 - 2"),
      equals(ListNode.makeList([
        Primitive.DIFFERENCE, 
          Primitive.QUOTIENT, 
            Primitive.POWER, 
               new NumberNode.int(2),
               Primitive.POWER, 
                 new NumberNode.float(3.5),
                 Primitive.SUM,
                 new NumberNode.int(7),
                 new NumberNode.int(1),
            new NumberNode.int(3),
          new NumberNode.int(2)])));
      });
      test("parse parenthesized expr", () {
        expect(
          parser.parse("(:g > 2)"),
          equals(ListNode.makeList(
            [Primitive.GREATERTHAN,
             Primitive.THING, Primitive.QUOTE, new WordNode("g"),
             new NumberNode.int(2)])
          ));
      });
    });
  }
}

void main() {
  new ParserTest().run();
}
