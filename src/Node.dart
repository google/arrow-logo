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

// Node
//   ListNode
//     Cons(head, tail)
//     Nil()
//   WordNode
//     Int(i)
//     Float(f)
//     Prim(p, arity, name[, altName])
//     String(s)
//     Ident(n)
//     Defn(name, arity, body)
//   Primitive  // see Primitive.dart
class Node {

  static final int KIND_WORD = 0;
  static final int KIND_LIST = 1;
  static final int KIND_PRIM = 2;
  static final int KIND_MASK = 3;
  
  final int tag;

  const Node(this.tag);
   
  bool isWord() { return (tag & KIND_MASK) == KIND_WORD; }
  bool isList() { return (tag & KIND_MASK) == KIND_LIST; }
  bool isPrim() { return (tag & KIND_MASK) == KIND_PRIM; }
}

class ListNode extends Node {

  static final int LIST_NIL = 0 << 2;
  static final int LIST_CONS = 1 << 2;
  static final int LIST_MASK = 1 << 2;

  bool isNil()  { return (tag & LIST_MASK) == LIST_NIL; }
  bool isCons() { return (tag & LIST_MASK) == LIST_CONS; }
  
  bool operator ==(node) {
    if (!(node is ListNode)) {
      return false;
    }
    ListNode that = node;
    return (isNil() && that.isNil())
        || (getHead() == that.getHead() && getTail() == that.getTail());
  }
  
  static Node NIL = null;
  static ListNode makeNil() {
    if (NIL == null) {
      NIL = new ListNode(LIST_NIL);
    }
    return NIL;
  }
  
  static Node makeCons(Node head, ListNode tail) {
    return new ListNode(LIST_CONS, head, tail);
  }
  
  static Node makeList(List list) {
    var n = makeNil();
    while (!list.isEmpty()) {
      n = makeCons(list.removeLast(), n);
    }
    return n;
  }
  
  Node head;
  ListNode tail;
  
  ListNode(int tag, [this.head = null, this.tail = null]) : super(tag | Node.KIND_LIST) {}  
  
  Node getHead() { return head; }
  ListNode getTail() { return tail; }
  int getLength() { 
    return getLengthIter(0); 
  }
  int getLengthIter(int acc) { 
    return isNil() ? acc : tail.getLengthIter(1 + acc); 
  }
  ListNode getPrefix(int length) {
    return (length <= 0) 
        ? this
        : makeCons(getHead(), getTail().getPrefix(length - 1));
  }
  ListNode getSuffix(int length) {
    return (length <= 0)
        ? this
        : getTail().getSuffix(length - 1);
  }
  ListNode append(ListNode rest) {
    return isNil() ? rest : makeCons(head, tail.append(rest));
  }
  
  String toString() {
    if (isNil()) {
      return "Nil()";
    } else if (isCons()) {
      return "Cons(${getHead().toString()},${getTail().toString()})";
    }
    return null;
  }
}

class WordNode extends Node {
  
  static final int WORD_INT    = 1 << 2;
  static final int WORD_FLOAT  = 2 << 2;
  static final int WORD_STRING = 3 << 2;
  static final int WORD_IDENT  = 4 << 2;
  static final int WORD_DEFN   = 5 << 2;
  static final int WORD_MASK   = 7 << 2;

  int arity;         // Defn
  
  int intValue;      // Int
  double floatValue; // Float
  String strValue;   // String, Ident, Defn
  
  ListNode body;     // Defn
  
  WordNode(int tag) : super(tag | Node.KIND_WORD);
  
  bool operator ==(Object node) {
    if (!(node is WordNode)) {
      return false;
    }
    WordNode that = node;
    if (tag != that.tag) {
      return false;
    }
    return (isIdent() && getIdentName() == that.getIdentName())
        || (isInt() && getIntValue() == that.getIntValue())
        || (isFloat() && getFloatValue() == that.getFloatValue())
        || (isString() && getStringValue() == that.getStringValue())
        || (isDefn() && getDefnName() == that.getDefnName() 
                     && getDefnBody() == that.getDefnBody());
  }
  
  bool isIdent() { return (tag & WORD_MASK) == WORD_IDENT; }
  bool isInt() { return (tag & WORD_MASK) == WORD_INT; }
  bool isFloat() { return (tag & WORD_MASK) == WORD_FLOAT; }
  bool isNum() { return isInt() || isFloat(); }
  bool isString() { return (tag & WORD_MASK) == WORD_STRING; }
  bool isDefn() { return (tag & WORD_MASK) == WORD_DEFN; }

  String getIdentName() {
    return strValue;
  }
  
  int getIntValue() {
    return intValue;
  }

  double getFloatValue() {
    return isInt() ? intValue.toDouble() : floatValue;
  }
  
  num getNumValue() {
    if (isInt())
      return intValue;
    if (isFloat())
      return floatValue;
    throw new Exception("neither int nor float");
  }

  String getStringValue() {
    return strValue;
  }

  String getDefnName() {
    return strValue;
  }
  
  ListNode getDefnBody() {
    return body;
  }
  
  String getName() {
    return strValue;
  }
    
  int getArity() {
    return arity;
  }

  String toString() {
    if (isFloat()) {
      return "Float(${getFloatValue()})";
    } else if (isIdent()) {
      return "Ident(${getStringValue()})";
    } else if (isInt()) {
      return "Int(${getIntValue()})";
    } else if (isString()) {
      return "String(${getStringValue()})";
    } else if (isDefn()) {
      return "Defn(${getDefnName()},${getArity()},${getDefnBody()})";
    }
    return null;
  }
    

  static Node makeIdent(String identName) {
    WordNode wn = new WordNode(WORD_IDENT);
    wn.strValue = identName;
    return wn;
  }
  
  static Node makeInt(int intValue) {
    WordNode wn = new WordNode(WORD_INT);
    wn.intValue = intValue;
    return wn;
  }
  
  static Node makeFloat(double floatValue) {
    WordNode wn = new WordNode(WORD_FLOAT);
    wn.floatValue = floatValue;
    return wn;
  }
  
  static Node makeString(String strValue) {
    WordNode wn = new WordNode(WORD_STRING);
    wn.strValue = strValue;
    return wn;
  }
  
  static Node makeDefn(String name, int arity, ListNode body) {
    WordNode wn = new WordNode(WORD_DEFN);
    wn.strValue = name;
    wn.arity = arity;
    wn.body = body;
    return wn;
  }
}
