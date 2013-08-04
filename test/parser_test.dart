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
library parser_test;

import 'package:unittest/unittest.dart';

import "package:arrowlogo/nodes.dart";
import "package:arrowlogo/parser.dart";

class ParserTest {

  final Parser parser;
  
  ParserTest() 
      : parser = new Parser(Primitive.getBuiltIns());
  
  void testAdvanceWhile() {
    Scanner s = parser;
    s.initialize("  a");
    expect(s.advanceWhile(Scanner.isSpace), equals(2));
    s.initialize("a");
    expect(s.advanceWhile(Scanner.isSpace), equals(0));
    s.initialize("abc");
    expect(s.advanceWhile(Scanner.isAlpha), equals(3));
    s.initialize("12a");
    expect(s.advanceWhile(Scanner.isDigit), equals(2));
    s.initialize(".2a");
    expect(s.advanceWhile(Scanner.isDigitOrDot), equals(2));
  }
  
  void testTokenizeNum() {
    parser.initialize("1");
    parser.tokenizeNum();
    expect(parser.pos, equals("1".length));
    expect(parser.token.kind, equals(Token.TOKEN_NUM));    
    expect(parser.token.node.isNum(), true);
    Node n = parser.token.node;
    expect(n.isNum(), true);
    NumberNode numInt = n;
    expect(numInt.isInt(), true);
    expect(1, numInt.getIntValue());

    parser.initialize("1.2x");
    parser.tokenizeNum();
    expect(parser.pos, equals("1.2".length));
    expect(parser.token.kind, equals(Token.TOKEN_NUM));
    expect(parser.token.node.isNum(), true);
    n = parser.token.node;
    expect(n.isNum(), true);
    NumberNode numFloat = n;
    expect(numFloat.isFloat(), true);
    expect(1.2, numFloat.getFloatValue());
  }
  
  void testTokenizeWordOrKeyword() {
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
  }
  
  void testParseSomeAtoms() {
    expect(new NumberNode.int(1), equals(new NumberNode.int(1)));  // sanity
    expect(
      parser.parse("fd 1 fd 1.2 \"baz"),
      equals(ListNode.makeList([
        Primitive.FORWARD, new NumberNode.int(1),
        Primitive.FORWARD, new NumberNode.float(1.2),
        new WordNode("\"baz")])
      ));
  }
  
  void testParseSomeLists() {  
    expect(
      parser.parse("[]"),
      equals(ListNode.makeList([ListNode.NIL])));
    expect(
      parser.parse("[1]"),
      equals(ListNode.makeList([ListNode.makeList([new NumberNode.int(1)])])));
    expect(
      parser.parse("pr [ 1 [ 1.2 ] [] fd 2 ]"),
      equals(ListNode.makeList([
        Primitive.PRINT,
        ListNode.makeList([
          new NumberNode.int(1), 
          ListNode.makeList([new NumberNode.float(1.2)]), 
          ListNode.NIL,
          Primitive.FORWARD,
          new NumberNode.int(2)])])
      ));
  }
  
  void testParseSomeDefs() {
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
          ListNode.makeList([new WordNode("\"size")]),
          ListNode.makeList([                                                             
            Primitive.FORWARD,
            Primitive.THING, new WordNode("\"size")]))]) 
      ));
  }

  void testParseInfixExpr() {

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
  }
  
  void testParseParen() {    
    expect(
      parser.parse("(:g > 2)"),
      equals(ListNode.makeList(
        [Primitive.GREATERTHAN,
         Primitive.THING, new WordNode("\"g"),
         new NumberNode.int(2)])
      ));
  }
  
  void run() {
    group("ParserTest", () {
      test("advance while", testAdvanceWhile);
      test("tokenize num", testTokenizeNum);
      test("tokenize word or keyword", testTokenizeWordOrKeyword);
      test("parse some words and numbers", testParseSomeAtoms);
      test("parse some lists", testParseSomeLists);
      test("parse some defns", testParseSomeDefs);
      test("parse infix expr", testParseInfixExpr);
      test("parse parenthesized expr", testParseParen);
    });
  }
}
