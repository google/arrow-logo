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
import 'nodes.dart';

class ParseException {
  final String message;
  const ParseException(this.message);
}

typedef bool CharPredicate(int);

class Token {
  static const TOKEN_EOF = -1;
  static const TOKEN_NUM = 0;
  static const TOKEN_WORD = 1;
  static const TOKEN_PRIM = 2;
  static const TOKEN_LBRACE = 123;
  static const TOKEN_RBRACE = 125;
  static const TOKEN_LBRACKET = 91;
  static const TOKEN_RBRACKET = 93;

  static const TOKEN_LPAREN = 40;
  static const TOKEN_RPAREN = 41;

  static const TOKEN_TO = 42;
  static const TOKEN_VAR = 44;
  static const TOKEN_OUTPUT = 45;
  static const TOKEN_END = 46;

  static const TOKEN_POUND = 51;
  static const TOKEN_PLUS = 52;
  static const TOKEN_MINUS = 53;
  static const TOKEN_SLASH = 54;
  static const TOKEN_STAR = 55;
  static const TOKEN_CARET = 56;

  static const TOKEN_LT = 57;
  static const TOKEN_GT = 58;
  static const TOKEN_LE = 59;
  static const TOKEN_GE = 60;
  static const TOKEN_EQ = 61;
  static const TOKEN_EQEQ = 62;
  static const TOKEN_PERCENT = 63;

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

  Token setPrim(Primitive p) => setKind(TOKEN_PRIM).setNode(p);
  Token setWord(WordNode word) => setKind(TOKEN_WORD).setNode(word);

  Token setVar(WordNode v) => setKind(TOKEN_VAR).setNode(v);
  Token setNum(NumberNode n) => setKind(TOKEN_NUM).setNode(n);
  Token setEof() => setKind(TOKEN_EOF).setNode(null);

  String toString() {
    switch (kind) {
      case TOKEN_EOF:
        return "EOF";
      case TOKEN_PRIM:
        return "PRIM";
      case TOKEN_NUM:
        return "NUM";
      case TOKEN_WORD:
        return "WORD";
      case TOKEN_PRIM:
        return "PRIM";
      case TOKEN_LBRACE:
        return "LBRACE";
      case TOKEN_RBRACE:
        return "RBRACE";
      case TOKEN_LBRACKET:
        return "LBRACKET";
      case TOKEN_RBRACKET:
        return "RBRACKET";
      case TOKEN_LPAREN:
        return "LPAREN";
      case TOKEN_RPAREN:
        return "RPAREN";
      case TOKEN_TO:
        return "TO";
      case TOKEN_VAR:
        return "VAR";
      case TOKEN_OUTPUT:
        return "OUTPUT";
      case TOKEN_END:
        return "END";

      case TOKEN_POUND:
        return "#";
      case TOKEN_PLUS:
        return "PLUS";
      case TOKEN_MINUS:
        return "MINUS";
      case TOKEN_SLASH:
        return "SLASH";
      case TOKEN_STAR:
        return "STAR";
      case TOKEN_CARET:
        return "CARET";

      case TOKEN_LT:
        return "LT";
      case TOKEN_GT:
        return "GT";
      case TOKEN_LE:
        return "LE";
      case TOKEN_GE:
        return "GE";
      case TOKEN_EQ:
        return "EQ";
      case TOKEN_EQEQ:
        return "EQEQ";
      case TOKEN_PERCENT:
        return "PERCENT";

      default:
        return "???";
    }
  }

  bool isInfixOp() {
    switch (kind) {
      case TOKEN_PERCENT:
      case TOKEN_PLUS:
      case TOKEN_POUND:
      case TOKEN_MINUS:
      case TOKEN_SLASH:
      case TOKEN_STAR:
      case TOKEN_CARET:
      case TOKEN_EQ:
      case TOKEN_EQEQ:
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
      case Token.TOKEN_LPAREN:
      case Token.TOKEN_LBRACKET:
        return true;
      default:
        return false;
    }
  }

  Primitive getInfixOp() {
    switch (kind) {
      case TOKEN_PERCENT:
        return Primitive.REMAINDER;
      case TOKEN_PLUS:
        return Primitive.SUM;
      case TOKEN_POUND:
        return Primitive.SELECT;
      case TOKEN_MINUS:
        return Primitive.DIFFERENCE;
      case TOKEN_SLASH:
        return Primitive.QUOTIENT;
      case TOKEN_STAR:
        return Primitive.PRODUCT;
      case TOKEN_CARET:
        return Primitive.POWER;
      case TOKEN_EQ:
        return Primitive.EQUALS;
      case TOKEN_EQEQ:
        return Primitive.EQUALS;
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
  static const CHAR_0 = 48; // "0".charCodeAt(0) is not a constant
  static const CHAR_9 = 57;
  static const CHAR_a = 97;
  static const CHAR_z = 122;
  static const CHAR_A = 65;
  static const CHAR_Z = 90;
  static const CHAR_BLANK = 32;
  static const CHAR_QUOTE = 34;
  static const CHAR_DOT = 46;
  static const CHAR_TAB = 9;
  static const CHAR_NEWLINE = 10;
  static const CHAR_COLON = 58;
  static const CHAR_SEMI = 59;
  static const CHAR_UNDERSCORE = 95;
  static const CHAR_NBSP = 160;

  static bool isAlpha(dynamic charCode) =>
      (CHAR_a <= charCode && charCode <= CHAR_z) ||
      (CHAR_A <= charCode && charCode <= CHAR_Z);

  static bool isDigit(dynamic charCode) =>
      (CHAR_0 <= charCode && charCode <= CHAR_9);

  static bool isUnderscore(dynamic charCode) => CHAR_UNDERSCORE == charCode;

  static bool isDigitOrDot(dynamic charCode) =>
      CHAR_DOT == charCode || isDigit(charCode);

  static bool isDot(dynamic charCode) => CHAR_DOT == charCode;

  static bool isSpace(dynamic charCode) => CHAR_BLANK == charCode;

  static bool isWhiteSpace(dynamic charCode) =>
      CHAR_BLANK == charCode ||
      CHAR_TAB == charCode ||
      CHAR_NEWLINE == charCode ||
      CHAR_NBSP == charCode;

  bool isAlphaOrDigitOrUnderscore(dynamic charCode) =>
      isAlpha(charCode) || isDigit(charCode) || isUnderscore(charCode);

  bool notNewLine(dynamic charCode) => CHAR_NEWLINE != charCode;

  /** 
   * Advances [pos] if f(text.charCodeAt(pos)) holds.
   */
  int advanceIf(bool f(int)) {
    final len = text.length;
    if (pos == len) {
      return pos;
    }
    final ch = text.codeUnitAt(pos);
    if (f(ch)) {
      ++pos;
    }
    return pos;
  }

  /** 
   * Advances [pos] until the following holds:
   * 
   * !f(text.charCodeAt(pos)) || pos == text.length
   * 
   * */
  int advanceWhile(CharPredicate f) {
    final len = text.length;
    if (pos == len) {
      return pos;
    }
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

  final Map<String, Node> toplevel;
  final Token token;
  String text;
  int pos;

  /** @param toplevel used for looking up keywords (lowercase forms) */
  Scanner(this.toplevel) : token = new Token();

  void initialize(String text) {
    this.text = text;
    this.pos = 0;
  }

  /**
   * @pre  text.charCodeAt(0) == CHAR_COLON
   * @post token.kind == Token.TOKEN_VAR
   * @post token.node.isWord()
   */
  void tokenizeVar() {
    final start = ++pos;
    if (!isAlpha(text.codeUnitAt(pos))) {
      throw new Exception("expected alphabetical");
    }
    advanceWhile(isAlphaOrDigitOrUnderscore);
    String word = text.substring(start, pos);
    token.setVar(new WordNode(word));
  }

  /**
   * @post token.kind == Token.TOKEN_NUM
   * @post token.node.isNum()
   */
  void tokenizeNum() {
    final start = pos;
    advanceWhile(isDigit);
    advanceIf(isDot);
    advanceWhile(isDigit);

    final numtext = text.substring(start, pos);
    final nn = numtext.contains(".")
        ? new NumberNode.float(double.parse(numtext))
        : new NumberNode.int(int.parse(numtext));
    token.setNum(nn);
  }

  /** @post token.kind \in {TOKEN_TO, TOKEN_END, TOKEN_WORD, TOKEN_PRIM} */
  void tokenizeWord() {
    final start = pos;
    advanceWhile(isAlphaOrDigitOrUnderscore);
    final word = text.substring(start, pos);
    if (word == "to") {
      token.kind = Token.TOKEN_TO;
    } else if (word == "end") {
      token.kind = Token.TOKEN_END;
    } else {
      Node p = toplevel[word.toLowerCase()];
      if (p == null || !p.isPrim)
        token.setWord(new WordNode(word));
      else
        token.setPrim(p);
    }
  }

  void tokenizeSpecial() {
    switch (text[pos]) {
      case '#':
        token.setKind(Token.TOKEN_POUND);
        break;
      case '(':
        token.setKind(Token.TOKEN_LPAREN);
        break;
      case ')':
        token.setKind(Token.TOKEN_RPAREN);
        break;
      case '{':
        token.setKind(Token.TOKEN_LBRACE);
        break;
      case '}':
        token.setKind(Token.TOKEN_RBRACE);
        break;
      case '[':
        token.setKind(Token.TOKEN_LBRACKET);
        break;
      case ']':
        token.setKind(Token.TOKEN_RBRACKET);
        break;
      case '+':
        token.setKind(Token.TOKEN_PLUS);
        break;
      case '-':
        token.setKind(Token.TOKEN_MINUS);
        break;
      case '*':
        token.setKind(Token.TOKEN_STAR);
        break;
      case '/':
        token.setKind(Token.TOKEN_SLASH);
        break;
      case '%':
        token.setKind(Token.TOKEN_PERCENT);
        break;
      case '^':
        token.setKind(Token.TOKEN_CARET);
        break;
      case '<':
        if (text.length > pos + 1 && text[pos + 1] == '=') {
          token.setKind(Token.TOKEN_LE);
          pos += 2;
          return;
        }
        token.setKind(Token.TOKEN_LT);
        break;
      case '>':
        if (text.length > pos + 1 && text[pos + 1] == '=') {
          token.setKind(Token.TOKEN_GE);
          pos += 2;
          return;
        }
        token.setKind(Token.TOKEN_GT);
        break;
      case '=':
        if (text.length > pos + 1 && text[pos + 1] == '=') {
          token.setKind(Token.TOKEN_EQEQ);
          pos += 2;
          return;
        }
        token.setKind(Token.TOKEN_EQ);
        break;

      default:
        throw new Exception(
          "unexpected char: '${text[pos]} (${text.codeUnitAt(pos)})'");
    }
    ++pos;
  }

  void skipComment() {
    advanceWhile(notNewLine);
  }

  /**
   * Tokenizes a prefix of `text'.
   *
   * @pre text == text.trim()
   * @post this.token is set to appropriate value
   */
  void tokenize() {
    final charCode = text.codeUnitAt(pos);
    if (CHAR_COLON == charCode) {
      tokenizeVar();
    } else if (CHAR_QUOTE == charCode) {
      ++pos;
      if (pos == text.length) {
        token.setWord(new WordNode("")); // empty word
      } else if (pos < text.length && isWhiteSpace(text.codeUnitAt(pos))) {
        ++pos;
        token.setWord(new WordNode("")); // empty word
      } else {
        token.setPrim(Primitive.QUOTE);
      }
    } else if (isDigitOrDot(charCode)) {
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

    while (isWhiteSpace(text.codeUnitAt(pos))
          || CHAR_SEMI == text.codeUnitAt(pos)) {
      advanceWhile(isWhiteSpace);
      if (pos == text.length) {
        token.setEof();
        return;
      }
      if (CHAR_SEMI == text.codeUnitAt(pos)) {
        skipComment();
      }
      if (pos == text.length) {
        token.setEof();
        return;
      }
    }
    tokenize();
  }
}

class OpInfo {
  final Primitive binop;
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

  Parser(Map<String, Node> toplevel)
      : opstack = null,
        super(toplevel);

  /**
   * @pre token.kind == TOKEN_LBRACKET
   * @post nodeList' = nodeList ++ listNode
   */
  void parseList(List<Node> nodeList) {
    final objList = <Node>[];

    nextToken();
    while (
        token.kind != Token.TOKEN_EOF && token.kind != Token.TOKEN_RBRACKET) {
      parseExpr(objList);
    }
    nodeList.add(ListNode.makeList(objList));
    nextToken();
  }

  /**
   *     atom ::= int | float | word | var | quote word
   */
  void parseAtom(List<Node> nodeList) {
    switch (token.kind) {
      case Token.TOKEN_PRIM:
      case Token.TOKEN_NUM:
      case Token.TOKEN_WORD:
        var node = token.node;
        nodeList.add(node);
        nextToken();
        if (node == Primitive.QUOTE) {
          nodeList.add(token.node);
          nextToken();
        }
        return;
      case Token.TOKEN_VAR:
        nodeList.add(Primitive.THING);
        nodeList.add(Primitive.QUOTE);
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
  List<Node> reduceStack(
      OpInfo base, List<Node> top0, int prec, bool isLeftAssoc) {
    List<Node> result = top0;
    while (opstack != base &&
        (prec < opstack.binop.precedence ||
            (isLeftAssoc && prec == opstack.binop.precedence))) {
      OpInfo top = opstack;
      List<Node> tmp = [top.binop];
      tmp.addAll(top.operand);
      tmp.addAll(result);
      result = tmp;
      opstack = opstack.next;
    }
    return result;
  }

  /**
   *     part ::= atom | list | '(' expr ')'
   */
  void parsePart(List<Node> nodeList) {
    switch (token.kind) {
      case Token.TOKEN_PRIM:
      case Token.TOKEN_NUM:
      case Token.TOKEN_WORD:
      case Token.TOKEN_VAR:
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
    List<Node> operand = <Node>[];
    OpInfo base = opstack;

    parsePart(operand);
    while (token.isInfixOp()) {
      Primitive binop = token.getInfixOp();
      operand = reduceStack(base, operand, binop.precedence, binop.isLeftAssoc);
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
    while (token.kind != Token.TOKEN_EOF && token.isExprStart()) {
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
    final wn = token.node as WordNode;
    final name = wn.stringValue;
    nextToken();
    final varList = <Node>[];
    while (token.kind == Token.TOKEN_VAR) {
      varList.add(token.node);
      nextToken();
    }
    final objList = <Node>[];
    while (token.kind != Token.TOKEN_END && token.kind != Token.TOKEN_EOF) {
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
    nodeList.add(new DefnNode(
        name, ListNode.makeList(varList), ListNode.makeList(objList)));
  }

  /**
   * Parses [input] to list of nodes.
   */
  ListNode parse(String input) {
    input = input.trim();
    initialize(input);
    final nodeList = <Node>[];
    nextToken();
    while (token.kind != Token.TOKEN_EOF) {
      switch (token.kind) {
        case Token.TOKEN_WORD:
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
