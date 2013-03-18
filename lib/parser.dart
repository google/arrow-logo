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
library parser;

import 'dart:math' as math;

import 'nodes.dart';

class ParseException {
  final String message;
  const ParseException(this.message);
}

class Token {

  static const int TOKEN_EOF = -1;
  static const int TOKEN_NUM = 0;
  static const int TOKEN_WORD = 1;
  static const int TOKEN_PRIM = 2;
  static const int TOKEN_QUOTED_WORD = 3;
  static const int TOKEN_LBRACE = 123;
  static const int TOKEN_RBRACE = 125;
  static const int TOKEN_LBRACKET = 91;
  static const int TOKEN_RBRACKET = 93;
  
  static const int TOKEN_LPAREN = 40;
  static const int TOKEN_RPAREN = 41;  

  static const int TOKEN_TO = 42;
  static const int TOKEN_VAR = 44;
  static const int TOKEN_OUTPUT = 45;
  static const int TOKEN_END = 46;

  static const int TOKEN_PLUS = 52;  
  static const int TOKEN_MINUS = 53;  
  static const int TOKEN_SLASH = 54;  
  static const int TOKEN_STAR = 55;  
  static const int TOKEN_CARET = 56; 

  static const int TOKEN_LT = 57;  
  static const int TOKEN_GT = 58;  
  static const int TOKEN_LE = 59;  
  static const int TOKEN_GE = 60;  
  static const int TOKEN_EQ = 61;  

  int kind;
  Node node;
  
  Token setKind(int kind_) {
    this.kind = kind_;
    return this;
  }
  
  Token setNode(Node node_) {
    this.node = node_;
    return this;
  }
  
  Token setPrim(Primitive p)     => setKind(TOKEN_PRIM).setNode(p);
  Token setWord(WordNode word)   => setKind(TOKEN_WORD).setNode(word);
  Token setQuotedWord(WordNode word) => 
      setKind(TOKEN_QUOTED_WORD).setNode(word);
  Token setVar(WordNode v)       => setKind(TOKEN_VAR).setNode(v);
  Token setNum(NumberNode n)     => setKind(TOKEN_NUM).setNode(n);
  Token setEof()                 => setKind(TOKEN_EOF).setNode(null);
  
  String toString() {
    switch (kind) {
      case TOKEN_EOF: return "EOF";
      case TOKEN_PRIM: return "PRIM";
      case TOKEN_NUM: return "NUM";
      case TOKEN_WORD: return "WORD";
      case TOKEN_PRIM: return "PRIM";
      case TOKEN_WORD: return "QUOTED_WORD";
      case TOKEN_LBRACE: return "LBRACE";
      case TOKEN_RBRACE: return "RBRACE";
      case TOKEN_LBRACKET: return "LBRACKET";
      case TOKEN_RBRACKET: return "RBRACKET";
      case TOKEN_LPAREN: return "LPAREN";
      case TOKEN_RPAREN: return "RPAREN";
      case TOKEN_TO: return "TO";
      case TOKEN_VAR: return "VAR";
      case TOKEN_OUTPUT: return "OUTPUT";
      case TOKEN_END: return "END";      

      case TOKEN_PLUS: return "PLUS";  
      case TOKEN_MINUS: return "MINUS";  
      case TOKEN_SLASH: return "SLASH";  
      case TOKEN_STAR: return "STAR";  
      case TOKEN_CARET: return "CARET";  

      case TOKEN_LT: return "LT";  
      case TOKEN_GT: return "GT";  
      case TOKEN_LE: return "LE";  
      case TOKEN_GE: return "GE";  
      case TOKEN_EQ: return "EQ";  

      default: return "???";
    }
  }
  
  bool isInfixOp() {
    switch (kind) {
      case TOKEN_PLUS:
      case TOKEN_MINUS:
      case TOKEN_SLASH:
      case TOKEN_STAR:
      case TOKEN_CARET:
      case TOKEN_LT:
      case TOKEN_LE:
      case TOKEN_GT:
      case TOKEN_LE:
        return true;
      default:
        return false;
    }
  }
  
  bool isExprStart() {
    switch (kind) {
      case Token.TOKEN_PRIM:
      case Token.TOKEN_NUM:
      case Token.TOKEN_WORD:
      case Token.TOKEN_VAR:
      case Token.TOKEN_QUOTED_WORD:
      case Token.TOKEN_LPAREN:
      case Token.TOKEN_LBRACKET:
        return true;
      default:
        return false;
    }
  }
  
  Primitive getInfixOp() {
    switch (kind) {
      case TOKEN_PLUS:
        return Primitive.SUM;
      case TOKEN_MINUS:
        return Primitive.DIFFERENCE;
      case TOKEN_SLASH:
        return Primitive.QUOTIENT;
      case TOKEN_STAR:
        return Primitive.PRODUCT;
      case TOKEN_CARET:
        return Primitive.POWER;
      case TOKEN_LT:
        return Primitive.LESSTHAN;
      case TOKEN_LE:
        return Primitive.LESSOREQUAL;
      case TOKEN_GT:
        return Primitive.GREATERTHAN;
      case TOKEN_GE:
        return Primitive.GREATEROREQUAL;
      default:
        return null;
    }
  }
}

class Scanner {
  static const int CHAR_0 = 48;  // "0".charCodeAt(0) is not a constant
  static const int CHAR_9 = 57; 
  static const int CHAR_a = 97; 
  static const int CHAR_z = 122;  
  static const int CHAR_A = 65;  
  static const int CHAR_Z = 90;  
  static const int CHAR_BLANK = 32; 
  static const int CHAR_QUOTE = 34; 
  static const int CHAR_DOT = 46; 
  static const int CHAR_TAB = 9; 
  static const int CHAR_NEWLINE = 10;
  static const int CHAR_COLON = 58; 
  
  static bool isAlpha(int charCode) =>
      (CHAR_a <= charCode && charCode <= CHAR_z)
      || (CHAR_A <= charCode && charCode <= CHAR_Z);
  
  static bool isDigit(int charCode) => 
      (CHAR_0 <= charCode && charCode <= CHAR_9);
  
  static bool isDigitOrDot(int charCode) => 
      CHAR_DOT == charCode || isDigit(charCode);
  
  static bool isSpace(int charCode) => 
      CHAR_BLANK == charCode;
      
  static bool isWhiteSpace(int charCode) =>
      CHAR_BLANK == charCode || CHAR_TAB == charCode
      || CHAR_NEWLINE == charCode;
  
  static bool isAlphaOrDigit(int charCode) =>
      isAlpha(charCode) || isDigit(charCode);
      
  /** 
   * Advances [pos] until the following holds:
   * 
   * !f(text.charCodeAt(pos)) || pos == text.length
   * 
   * */
  int advanceWhile(bool f(int)) {
    int len = text.length;
    int ch = text.codeUnitAt(pos);
    while (f(ch)) { 
      ++pos;
      if (pos == len) {
        return pos;
      }
      ch = text.codeUnitAt(pos);
    }
    return pos;
  }
  
  final Map<String, Primitive> toplevel;
  final Token token;
  String text;
  int pos;
  
  /** @param toplevel used for looking up keywords */
  Scanner(Map<String, Primitive> this.toplevel) : token = new Token();
  
  void initialize(String text) {
    this.text = text;
    this.pos = 0;
  }

  /**
   * @pre  text.charCodeAt(0) == CHAR_QUOTE
   * @post token.kind == Token.TOKEN_QUOTED_WORD
   * @post token.node.isWord()
   */
  void tokenizeQuotedWord() {
    int i = pos;
    ++pos;
    advanceWhile(isAlphaOrDigit);
    String word = text.substring(i, pos);
    token.setQuotedWord(new WordNode(word));
  }

  /**
   * @pre  text.charCodeAt(0) == CHAR_COLON
   * @post token.kind == Token.TOKEN_VAR
   * @post token.node.isWord()
   */
  void tokenizeVar() {
    int i = ++pos;
    if (!isAlpha(text.codeUnitAt(pos))) {
      throw new Exception("expected alphabetical");
    }
    advanceWhile(isAlphaOrDigit);
    String word = text.substring(i, pos);
    token.setVar(new WordNode("\"".concat(word)));
  }

  /**
   * @post token.kind == Token.TOKEN_NUM
   * @post token.node.isNum()
   */
  void tokenizeNum() {
    int i = pos;
    advanceWhile(isDigitOrDot);
    String numtext = text.substring(i, pos);
    NumberNode nn = numtext.contains(".")
        ? new NumberNode.float(double.parse(numtext))
        : new NumberNode.int(int.parse(numtext));
    token.setNum(nn);
  }
  
  /** @post token.kind \in {TOKEN_TO, TOKEN_END, TOKEN_WORD, TOKEN_PRIM} */
  void tokenizeWord() {
    int i = pos;
    advanceWhile(isAlphaOrDigit);
    String word = text.substring(i, pos);
    if (word == "to") {
      token.kind = Token.TOKEN_TO;
    } else if (word == "end") {
      token.kind = Token.TOKEN_END;
    } else {
      Node p = toplevel[word];
      if (p == null || !p.isPrim())
        token.setWord(new WordNode(word));
      else
        token.setPrim(p);
    }
  }
  
  void tokenizeSpecial() {
    switch (text[pos]) {
      case '(': token.setKind(Token.TOKEN_LPAREN); break;
      case ')': token.setKind(Token.TOKEN_RPAREN); break;
      case '{': token.setKind(Token.TOKEN_LBRACE); break;
      case '}': token.setKind(Token.TOKEN_RBRACE); break;
      case '[': token.setKind(Token.TOKEN_LBRACKET); break;
      case ']': token.setKind(Token.TOKEN_RBRACKET); break;
      case '+': token.setKind(Token.TOKEN_PLUS); break;
      case '-': token.setKind(Token.TOKEN_MINUS); break;
      case '*': token.setKind(Token.TOKEN_STAR); break;
      case '/': token.setKind(Token.TOKEN_SLASH); break;
      case '^': token.setKind(Token.TOKEN_CARET); break;
      case '<': 
        if (text.length > 1 && text[1] == '=') {
          token.setKind(Token.TOKEN_LE);
          pos += 2;
          return;
        }
        token.setKind(Token.TOKEN_LT);
        break;
      case '>':
        if (text.length > 1 && text[1] == '=') {
          token.setKind(Token.TOKEN_GE);
          pos += 2;
          return;
        }
        token.setKind(Token.TOKEN_GT);
        break;
      case '=': 
        token.setKind(Token.TOKEN_EQ);
        break;
    
      default: throw new Exception("unexpected char: ${text[0]}");
    }
    ++pos;
  }
  
  /**
   * Tokenizes a prefix of `text', returns rest.
   *
   * @pre text == text.trim()
   * @post this.token is set to appropriate value
   */
  void tokenize() {
    final int charCode = text.codeUnitAt(pos);
    if (CHAR_COLON == charCode) {
      tokenizeVar();
    } else if (CHAR_QUOTE == charCode) {
      tokenizeQuotedWord();
    } else if (isDigit(charCode)) {
      tokenizeNum();
    } else if (isAlpha(charCode)) {
      tokenizeWord();
    } else {
      tokenizeSpecial();
    }
  }
  
  /** Calls tokenize and trims whitespace */
  void nextToken() {
    if (pos == text.length) {
      token.setEof();
      return;
    }
    advanceWhile(isWhiteSpace);
    tokenize();
  }
}

class OpInfo {
  final Node binop;
  final List<Node> operand;
  final OpInfo next;
  
  const OpInfo(this.binop, this.operand, [this.next = null]);
  
  String toString() => "$binop $operand $next";
}

/**
 * Reads input and builds up an abstract syntax tree in the form of lists and
 * Node instances.
 *
 * recursive descent combined with operator-precedence parsing.
 * TODO adding "apply" nodes, and of course, error reporting.
 */
class Parser extends Scanner {
  
  OpInfo opstack;
  
  Parser(Map<String, Primitive> toplevel) : opstack = null, super(toplevel);
  
  /**
   * @pre token.kind == TOKEN_LBRACKET
   * @post nodeList' = nodeList ++ listNode
   */
  void parseList(List<Node> nodeList) {
    var objList = new List<Node>();
    
    nextToken();
    while (token.kind != Token.TOKEN_EOF
        && token.kind != Token.TOKEN_RBRACKET) {
      parseExpr(objList);
    }
    nodeList.add(ListNode.makeList(objList));
    nextToken();
  }
  
  /**
   *     atom ::= int | float | var | word | qword
   */ 
  void parseAtom(List<Node> nodeList) {
    switch (token.kind) {
      case Token.TOKEN_PRIM:
      case Token.TOKEN_NUM:
      case Token.TOKEN_WORD:
      case Token.TOKEN_QUOTED_WORD:
        nodeList.add(token.node);
        nextToken();
        return;
      case Token.TOKEN_VAR:
        nodeList.add(Primitive.THING);
        nodeList.add(token.node);
        nextToken();
        return;
      default:
        throw new Exception("unexpected token");
    }
  }
  
  /**
   * Operator precedence parsing.
   */
  List<Node> reduceStack(OpInfo base, List<Node> top0, int prec,
                         bool isLeftAssoc) {
    List<Node> result = top0;
    while (opstack != base
        && (prec < Primitive.getPrecedence(opstack.binop)
            || (isLeftAssoc 
                && prec == Primitive.getPrecedence(opstack.binop)))) {
      OpInfo top = opstack;
      List<Node> tmp = [opstack.binop];
      tmp.addAll(opstack.operand);
      tmp.addAll(result);
      result = tmp;
      opstack = opstack.next;
    }
    return result;
  }
  
  /**
   *     part ::= atom | list | '(' expr ')'
   */
  String parsePart(List<Node> nodeList) {
    switch (token.kind) {
      case Token.TOKEN_PRIM:
      case Token.TOKEN_NUM:
      case Token.TOKEN_WORD:
      case Token.TOKEN_VAR:
      case Token.TOKEN_QUOTED_WORD:
        parseAtom(nodeList);
        break;
      case Token.TOKEN_LBRACKET:
        parseList(nodeList);
        break;
      case Token.TOKEN_LPAREN:
        nextToken();
        parseExpr(nodeList);
        if (token.kind != Token.TOKEN_RPAREN) {
          throw new Exception("expected ')'");
        }
        nextToken();
        break;
    }
  }

  /**
   *      op ::= part (infix part)*
   */
  void parseOp(List<Node> nodeList) {
    List operand = [];
    OpInfo base = opstack;
    
    parsePart(operand);
    while (token.isInfixOp()) {
      Primitive binop = token.getInfixOp();
      operand = reduceStack(
          base, operand, Primitive.getPrecedence(binop), 
          Primitive.isLeftAssoc(binop));
      opstack = new OpInfo(binop, operand, opstack);
      nextToken();
      operand = [];
      if (token.isExprStart()) {
        parsePart(operand);
      } else {
        throw new Exception("expected expr");
      }
    }
    operand = reduceStack(base, operand, 0, true);
    nodeList.addAll(operand);
  }

  /**
   *     expr ::= op expr*
   */
  void parseExpr(List<Node> nodeList) {
    parseOp(nodeList);
    while (token.kind != Token.TOKEN_EOF
        && token.isExprStart()) {
      parseOp(nodeList);
    }
  }
  
  /**
   *     defn ::= 'to' word var* expr* 'end' 
   */
  void parseDefn(List<Node> nodeList) {
    nextToken();
    if (token.kind != Token.TOKEN_WORD) {
      throw new ParseException("expected word");
    }
    WordNode wn = token.node;
    String name = wn.stringValue;
    nextToken();
    var varList = new List<Node>();
    while (token.kind == Token.TOKEN_VAR) {
      varList.add(token.node);
      nextToken();
    }    
    var objList = new List<Node>();
    while (token.kind != Token.TOKEN_END
        && token.kind != Token.TOKEN_EOF) {
      parseExpr(objList);
    }
    if (token.kind == Token.TOKEN_EOF) {
      // ignore incomplete definition, to be handled by UI
      // TODO: move this constant to a reasonable place.
      nodeList.add(new WordNode("INCOMPLETE_DEFINITION"));
      nodeList.add(new WordNode(name));
      return;
    }
    nextToken();
    nodeList.add(
      new DefnNode(name,
        ListNode.makeList(varList), ListNode.makeList(objList)));
  }
     
  /**
   * Parses [input] to list of nodes.
   */
  ListNode parse(String input) {
    input = input.trim();
    initialize(input);
    var nodeList = new List<Node>();
    nextToken();
    while (token.kind != Token.TOKEN_EOF) {
      switch (token.kind) {
        case Token.TOKEN_WORD:
        case Token.TOKEN_QUOTED_WORD:
        case Token.TOKEN_PRIM:
        case Token.TOKEN_NUM:
        case Token.TOKEN_VAR:
        case Token.TOKEN_LPAREN:
          parseExpr(nodeList);
          break;
        case Token.TOKEN_LBRACKET:
          parseList(nodeList);
          break;
        case Token.TOKEN_TO:
          parseDefn(nodeList);
          break;
        default:
          throw new Exception("unexpected token: $token");
      }
    }
    
    return ListNode.makeList(nodeList);
  }
}
