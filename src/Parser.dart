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

class Token {

  static final int TOKEN_EOF = -1;
  static final int TOKEN_NUM = 0;
  static final int TOKEN_IDENT = 1;
  static final int TOKEN_PRIM = 2;
  static final int TOKEN_LBRACE = 123;
  static final int TOKEN_RBRACE = 125;
  static final int TOKEN_LBRACKET = 91;
  static final int TOKEN_RBRACKET = 93;
  
  static final int TOKEN_LPAREN = 40;
  static final int TOKEN_RPAREN = 41;  

  static final int TOKEN_TO = 42;
  static final int TOKEN_VAR = 44;
  static final int TOKEN_OUTPUT = 45;
  static final int TOKEN_END = 46;

  static final int TOKEN_PLUS = 52;  
  static final int TOKEN_MINUS = 53;  
  static final int TOKEN_SLASH = 54;  
  static final int TOKEN_STAR = 55;  
  static final int TOKEN_CARET = 56; 
  // todo
  static final int TOKEN_LT = 57;  
  static final int TOKEN_GT = 58;  
  static final int TOKEN_LE = 59;  
  static final int TOKEN_GE = 60;  
  static final int TOKEN_EQ = 61;  

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
  Token setIdent(WordNode ident) => setKind(TOKEN_IDENT).setNode(ident);
  Token setVar(WordNode v)       => setKind(TOKEN_VAR).setNode(v);
  Token setNum(WordNode n)       => setKind(TOKEN_NUM).setNode(n);
  Token setEof()                 => setKind(TOKEN_EOF).setNode(null);
  
  String toString() {
    switch (kind) {
      case TOKEN_EOF: return "EOF";
      case TOKEN_PRIM: return "PRIM";
      case TOKEN_NUM: return "NUM";
      case TOKEN_IDENT: return "IDENT";
      case TOKEN_PRIM: return "PRIM";
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
      case Token.TOKEN_IDENT:
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

class OpInfo {
  final Node binop;
  final List<Node> operand;
  final OpInfo next;
  
  const OpInfo(this.binop, this.operand, [this.next = null]);
  
  String toString() => "$binop $operand $next";
}

// Reads input and builds up an abstract syntax tree in the form of lists and
// Node instances.

// recursive descent combined with operator-precedence parsing.
// TODO adding "apply" nodes, and of course, error reporting.
class Parser {
  static final int CHAR_0 = 48;  // "0".charCodeAt(0) is not a constant
  static final int CHAR_9 = 57; 
  static final int CHAR_a = 97; 
  static final int CHAR_z = 122;  
  static final int CHAR_A = 65;  
  static final int CHAR_Z = 90;  
  static final int CHAR_BLANK = 32; 
  static final int CHAR_DOT = 46; 
  static final int CHAR_TAB = 9; 
  static final int CHAR_COLON = 58; 
  
  static bool isAlpha(int charCode) =>
      (CHAR_a <= charCode && charCode <= CHAR_z)
      || (CHAR_A <= charCode && charCode <= CHAR_Z);
  
  static bool isDigit(int charCode) => 
      (CHAR_0 <= charCode && charCode <= CHAR_9);
  
  static bool isDigitOrDot(int charCode) => 
      CHAR_DOT == charCode || isDigit(charCode);
  
  static bool isSpace(int charCode) => 
      CHAR_BLANK == charCode || CHAR_TAB == charCode;
  
  // return first index i>0 where !f(text.charCodeAt(i)) holds
  static int advanceWhile(String text, bool f(int)) {
    int i = 0;
    int len = text.length;
    int ch = text.charCodeAt(0);
    while (f(ch)) { 
      ++i;
      if (i == len) {
        return len;
      }
      ch = text.charCodeAt(i);
    }
    return i;
  }
  
  final Scope toplevel;
  final Token token;
  OpInfo opstack;
  
  Parser(Scope this.toplevel) : token = new Token(), opstack = null;
  
  // @pre  text.charCodeAt(0) == CHAR_COLON
  // @post token.kind == Token.TOKEN_VAR
  // @post token.node.isIdent()
  String tokenizeVar(String text) {
    String rtext = text.substring(1);
    if (rtext.isEmpty() || !isAlpha(rtext.charCodeAt(0))) {
      throw new Exception("expected alphanumeric");
    }
    int i = advanceWhile(rtext, isAlpha);
    String ident = text.substring(0, i + 1);
    rtext = rtext.substring(i);
    token.setVar(WordNode.makeIdent(ident));
    return rtext;
  }

  // @post token.kind == Token.TOKEN_NUM
  // @post token.node.isNum()
  String tokenizeNum(String text) {
    int i = advanceWhile(text, isDigitOrDot);
    String rest = text.substring(i);
    text = text.substring(0, i);
    WordNode wn = text.contains(".")
        ? WordNode.makeFloat(math.parseDouble(text))
        : WordNode.makeInt(math.parseInt(text));
    token.setNum(wn);
    return rest;
  }
  
  // @post token.kind \in {TOKEN_TO, TOKEN_END, TOKEN_IDENT, TOKEN_PRIM}  
  String tokenizeIdent(String text) {
    int i = advanceWhile(text, isAlpha);
    String rest = text.substring(i);
    text = text.substring(0, i);
    if (text == "to") {
      token.kind = Token.TOKEN_TO;
    } else if (text == "end") {
      token.kind = Token.TOKEN_END;
    } else {
      Primitive p = toplevel[text];
      if (p == null)
        token.setIdent(WordNode.makeIdent(text));
      else
        token.setPrim(p);
    }
    return rest;
  }
  
  String tokenizeSpecial(String text) {
    switch (text[0]) {
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
          return text.substring(2);
        }
        token.setKind(Token.TOKEN_LT);
        break;
      case '>': 
        if (text.length > 1 && text[1] == '=') {
          token.setKind(Token.TOKEN_GE);
          return text.substring(2);
        }
        token.setKind(Token.TOKEN_GT);
        break;
      case '=': 
        token.setKind(Token.TOKEN_EQ);
        break;
    
      default: throw new Exception("unexpected char: ${text[0]}");
    }
    return text.substring(1);
  }
  
  // Tokenizes a prefix of `text', returns rest.
  //
  // @pre text == text.trim()
  // @post this.token is set to appropriate value
  String tokenize(String text) {
    if (text.isEmpty()) {
      return text;
    }
    final int charCode = text.charCodeAt(0);
    if (CHAR_COLON == charCode) {
      return tokenizeVar(text);
    } else if (isDigit(charCode)) {
      return tokenizeNum(text);
    } else if (isAlpha(charCode)) {
      return tokenizeIdent(text);
    } else {
      return tokenizeSpecial(text);
    }
  }
  
  // Calls tokenize and trims whitespace
  String nextToken(String text) {
    if (text.isEmpty()) {
      token.setEof();
      return text;
    }
    return tokenize(text).trim();
  }
  
  // @pre token.kind == TOKEN_LBRACKET
  // @post nodeList' = nodeList ++ listNode
  String parseList(List<Node> nodeList, String input) {
    var objList = new List<Node>();
    
    input = nextToken(input);
    while (token.kind != Token.TOKEN_EOF
        && token.kind != Token.TOKEN_RBRACKET) {
      input = parseExpr(objList, input);
    }
    nodeList.add(ListNode.makeList(objList));
    return nextToken(input);
  }
  
  //
  // word ::= int | float | var | ident
  // 
  String parseWord(List<Node> nodeList, String input) {
    switch (token.kind) {
      case Token.TOKEN_PRIM:
      case Token.TOKEN_NUM:
      case Token.TOKEN_IDENT:
      case Token.TOKEN_VAR:
        nodeList.add(token.node);
        return nextToken(input);
      default:
        throw new Exception("unexpected token");
    }
  }
  
  //
  // operator precedence
  //
  List<Node> reduceStack(OpInfo base, List<Node> top0, int prec,
                         bool isLeftAssoc) {
    List<Node> result = top0;
    while (opstack !== base
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
  
  //
  // part ::= word | list | '(' expr ')'
  //
  String parsePart(List<Node> nodeList, String input) {
    switch (token.kind) {
      case Token.TOKEN_PRIM:
      case Token.TOKEN_NUM:
      case Token.TOKEN_IDENT:
      case Token.TOKEN_VAR:
        return parseWord(nodeList, input);
      case Token.TOKEN_LBRACKET:
        return parseList(nodeList, input);
      case Token.TOKEN_LPAREN:
        input = nextToken(input);
        input = parseExpr(nodeList, input);
        if (token.kind != Token.TOKEN_RPAREN) {
          throw new Exception("expected ')'");
        }
        return nextToken(input);
    }
  }

  //
  // op ::= part (infix part)*
  //
  String parseOp(List<Node> nodeList, String input) {
    List operand = [];
    OpInfo base = opstack;
    
    input = parsePart(operand, input);
    while (token.isInfixOp()) {
      Primitive binop = token.getInfixOp();
      operand = reduceStack(
          base, operand, Primitive.getPrecedence(binop), 
          Primitive.isLeftAssoc(binop));
      opstack = new OpInfo(binop, operand, opstack);
      input = nextToken(input);
      operand = [];
      if (token.isExprStart()) {
        input = parsePart(operand, input);
      } else {
        throw new Exception("expected expr");
      }
    }
    operand = reduceStack(base, operand, 0, true);
    nodeList.addAll(operand);
    return input;
  }

  //
  // expr ::= op expr*
  //
  String parseExpr(List<Node> nodeList, String input) {
    input = parseOp(nodeList, input);
    while (token.kind != Token.TOKEN_EOF
        && token.isExprStart()) {
      input = parseOp(nodeList, input);
    }
    return input;
  }
  
  //
  // defn ::= 'to' ident var* expr* 'end' 
  //
  String parseDefn(List<Node> nodeList, String input) {
    input = nextToken(input);
    if (token.kind != Token.TOKEN_IDENT) {
      throw new Exception("expected ident");
    }
    WordNode wn = token.node;
    String name = wn.getIdentName();
    input = nextToken(input);
    var objList = new List<Node>();
    int numVars = 0;
    while (token.kind == Token.TOKEN_VAR) {
      objList.add(token.node);
      input = nextToken(input);
      numVars++;
    }    
    while (token.kind != Token.TOKEN_END
        && token.kind != Token.TOKEN_EOF) {
      input = parseExpr(objList, input);
    }
    if (token.kind == Token.TOKEN_EOF) {
      // ignore incomplete definition, to be handled by UI
      // TODO: move this constant to a reasonable place.
      nodeList.add(WordNode.makeIdent("INCOMPLETE_DEFINITION"));
      nodeList.add(WordNode.makeIdent(name));
      return input;
    }
    input = nextToken(input);
    nodeList.add(
      WordNode.makeDefn(name, numVars, ListNode.makeList(objList)));
    return input;
  }
     
  // Parses `input' to list of nodes.
  ListNode parse(String input) {
    input = input.trim();
    var nodeList = new List<Node>();
    input = nextToken(input);
    while (token.kind != Token.TOKEN_EOF) {
      switch (token.kind) {
        case Token.TOKEN_IDENT:
        case Token.TOKEN_PRIM:
        case Token.TOKEN_NUM:
        case Token.TOKEN_VAR:
        case Token.TOKEN_LPAREN:
          input = parseExpr(nodeList, input);
          break;
        case Token.TOKEN_LBRACKET:
          input = parseList(nodeList, input);
          break;
        case Token.TOKEN_TO:
          input = parseDefn(nodeList, input);
          break;
        default:
          throw new Exception("unexpected token: $token");
      }
    }
    
    return ListNode.makeList(nodeList);
  }
}
