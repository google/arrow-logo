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

// Unit tests for Parser.
class ParserTest extends UnitTests {

  final Parser parser;
  
  ParserTest() 
      : parser = new Parser(new Scope(Primitive.getBuiltIns())) {}
  
  void testAdvanceWhile() {
    assertEquals(2, Parser.advanceWhile("  a", Parser.isSpace));
    assertEquals(0, Parser.advanceWhile("abc ", Parser.isSpace));
    assertEquals(3, Parser.advanceWhile("abc ", Parser.isAlpha));
    assertEquals(2, Parser.advanceWhile("12a", Parser.isDigit));
    assertEquals(2, Parser.advanceWhile(".2a", Parser.isDigitOrDot));
  }
  
  void testTokenizeNum() {
    assertEquals("", parser.tokenizeNum("1"));
    assertEquals(Token.TOKEN_NUM, parser.token.kind);
    assertTrue(parser.token.node.isWord());
    WordNode wn = parser.token.node;
    assertTrue(wn.isInt());
    assertEquals(1, wn.getIntValue());
    
    assertEquals("x", parser.tokenizeNum("1.2x"));
    assertEquals(Token.TOKEN_NUM, parser.token.kind);
    assertTrue(parser.token.node.isWord());
    wn = parser.token.node;
    assertTrue(wn.isFloat());
    assertEquals(1.2, wn.getFloatValue());
  }
  
  void testTokenizeIdentOrKeyword() {
    assertEquals("", parser.tokenizeIdent("fd"));
    assertEquals(Token.TOKEN_PRIM, parser.token.kind);
    assertEquals(Primitive.FORWARD, parser.token.node);   
  
    assertEquals("", parser.tokenizeIdent("x"));
    assertEquals(Token.TOKEN_IDENT, parser.token.kind);
    WordNode wn = parser.token.node;
    assertEquals("x", wn.getIdentName());   
  }
  
  void testParseSomeWords() {
    assertEquals(WordNode.makeInt(1), WordNode.makeInt(1));  // sanity
    assertEquals(ListNode.makeList([
        Primitive.FORWARD, WordNode.makeInt(1),
        Primitive.FORWARD, WordNode.makeFloat(1.2)]),
      parser.parse("fd 1 fd 1.2"));
  }
  
  void testParseSomeLists() {  
    assertEquals(
      ListNode.makeList([ListNode.NIL]), 
      parser.parse("[]"));
    assertEquals(
      ListNode.makeList([ListNode.makeList([WordNode.makeInt(1)])]), 
      parser.parse("[1]"));
    assertEquals(ListNode.makeList([
        Primitive.PRINT,
        ListNode.makeList([
          WordNode.makeInt(1), 
          ListNode.makeList([WordNode.makeFloat(1.2)]), 
          ListNode.NIL,
          Primitive.FORWARD,
          WordNode.makeInt(2)])]),
      parser.parse("pr [ 1 [ 1.2 ] [] fd 2 ]"));
  }
  
  void testParseSomeDefs() {
    assertEquals(
      ListNode.makeList(
        [WordNode.makeIdent("INCOMPLETE_DEFINITION"),
         WordNode.makeIdent("box")]),
      parser.parse("to box"));
    assertEquals(
      ListNode.makeList(
        [WordNode.makeDefn("box", 0, ListNode.NIL)]), 
      parser.parse("to box end"));
    assertEquals(
      ListNode.makeList(
        [WordNode.makeDefn("box", 0, ListNode.makeList([                                                             
          Primitive.FORWARD, WordNode.makeInt(10)]))]), 
      parser.parse("to box fd 10 end"));
    assertEquals(
      ListNode.makeList(
        [WordNode.makeDefn("box", 1, ListNode.makeList([                                                             
          WordNode.makeIdent(":size"),
          Primitive.FORWARD, WordNode.makeIdent(":size")]))]), 
      parser.parse("to box :size fd :size end"));
  }

  void testParseInfixExpr() {

    assertEquals(
      ListNode.makeList([WordNode.makeInt(2)]),
      parser.parse("2"));
    
    assertEquals(
      ListNode.makeList([
        Primitive.SUM,
          WordNode.makeInt(2), 
          WordNode.makeInt(2)]),
      parser.parse("2 + 2"));
    assertEquals(
      ListNode.makeList([
        Primitive.SUM, 
          Primitive.SUM, 
            WordNode.makeInt(2), 
            WordNode.makeInt(2), 
          WordNode.makeInt(2)]),
      parser.parse("2 + 2 + 2"));
    assertEquals(
      ListNode.makeList([
        Primitive.SUM, 
          WordNode.makeInt(2), 
          Primitive.PRODUCT, 
            WordNode.makeInt(3), 
            WordNode.makeInt(4)]),
      parser.parse("2 + 3 * 4"));
    assertEquals(
      ListNode.makeList([
        Primitive.SUM, 
        Primitive.PRODUCT, 
          WordNode.makeInt(3), 
          WordNode.makeInt(4),
        WordNode.makeInt(2)]),
      parser.parse("3 * 4 + 2"));
    assertEquals(
      ListNode.makeList([
        Primitive.DIFFERENCE, 
          Primitive.QUOTIENT, 
            Primitive.POWER, 
               WordNode.makeInt(2),
               Primitive.POWER, 
                 WordNode.makeFloat(3.5),
                 Primitive.SUM, 
                 WordNode.makeInt(7),
                 WordNode.makeInt(1),
            WordNode.makeInt(3),
          WordNode.makeInt(2)]),
      parser.parse("2^3.5^(7+1) / 3 - 2"));
  }
  
  void testParseParen() {
    print(parser.toplevel);
    assertEquals(
      ListNode.makeList(
        [Primitive.GREATERTHAN,
         WordNode.makeIdent(":g"),
         WordNode.makeInt(2)]),
      parser.parse("(:g > 2)"));
  }
  
  void run() {
    testAdvanceWhile();
    testTokenizeNum();
    testTokenizeIdentOrKeyword();
    testParseSomeWords();

    testParseSomeLists();
    testParseSomeDefs();
    testParseInfixExpr();
    testParseParen();
    print("ParserTest ok");
  }
}
