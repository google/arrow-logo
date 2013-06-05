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
part of nodes;

/** Represents an ArrowLogo object, primitive or definition.
 *  
 *     WordNode(sv)
 *     NumberNode
 *     - Int(iv)
 *     - Float(fv)
 *     ListNode
 *     - Cons(hd, tl)
 *     - Nil()
 *     Primitive  // see Primitive.dart
 *     Defn(name, arity, body)
 */
abstract class Node {
  
  static const int KIND_WORD = 0;
  static const int KIND_LIST = 1;
  static const int KIND_NUMBER = 2;
  static const int KIND_PRIM = 3;
  static const int KIND_DEFN = 4;

  static const int KIND_MASK = 7;
  static const int KIND_BITS = 3;
  
  final int tag;

  const Node(this.tag);
   
  bool isWord() { return (tag & KIND_MASK) == KIND_WORD; }
  bool isList() { return (tag & KIND_MASK) == KIND_LIST; }
  bool isNum() { return (tag & KIND_MASK) == KIND_NUMBER; }
  bool isPrim() { return (tag & KIND_MASK) == KIND_PRIM; }
  bool isDefn() { return (tag & KIND_MASK) == KIND_DEFN; }
}

class ListNode extends Node {
  
  static const int LIST_NIL = 0 << Node.KIND_BITS;
  static const int LIST_CONS = 1 << Node.KIND_BITS;
  static const int LIST_MASK = 1 << Node.KIND_BITS;

  bool isNil()  { return (tag & LIST_MASK) == LIST_NIL; }
  bool isCons() { return (tag & LIST_MASK) == LIST_CONS; }
  
  bool operator ==(node) {
    if (!(node is ListNode)) {
      return false;
    }
    ListNode that = node;
    return (isNil() && that.isNil())
        || (head == that.head && tail == that.tail);
  }
  
  Iterator<Node> get iterator => new ListNodeIterator(this);
  
  final Node head;
  final ListNode tail;
  
  const ListNode.nil()
      : head = null, tail = null, super(LIST_NIL | Node.KIND_LIST);  
  const ListNode.cons(this.head, this.tail)
      : super(LIST_CONS | Node.KIND_LIST);

  static const Node NIL = const ListNode.nil();
  
  static Node makeList(List list) {
    var n = NIL;
    while (!list.isEmpty) {
      n = new ListNode.cons(list.removeLast(), n);
    }
    return n;
  }
    
  int get length => _getLengthIter(0); 
  
  int _getLengthIter(int acc) { 
    return isNil() ? acc : tail._getLengthIter(1 + acc); 
  }
  
  ListNode getPrefix(int length) {
    return (length <= 0) 
        ? this
        : new ListNode.cons(head, tail.getPrefix(length - 1));
  }
  
  ListNode getSuffix(int length) {
    return (length <= 0)
        ? this
        : tail.getSuffix(length - 1);
  }
  
  ListNode append(ListNode rest) {
    return isNil() ? rest : new ListNode.cons(head, tail.append(rest));
  }
  
  String toString() {
    return isNil() ? "[]" : _toStringIter("[");
  }
  
  String _toStringIter(String acc) {
    return isNil()
        ? (acc + " ]")
        : tail._toStringIter(acc + " " + head.toString());
  }
}

class ListNodeIterator implements Iterator<Node> {
  
  ListNode nodes;  
  ListNodeIterator(ListNode nodes) {
    print(nodes);
    this.nodes = new ListNode.cons(null, nodes);
  }
  
  Node get current {
    if (nodes.isNil()) {
      throw new Exception();
    }
    return nodes.head;
  }
  
  bool moveNext() {
    nodes = nodes.tail;
    return !nodes.isNil();
  }
}

class WordNode extends Node {
  
  final String stringValue;
  
  const WordNode(this.stringValue) : super(Node.KIND_WORD);
  
  bool operator ==(Object node) {
    if (!(node is WordNode)) {
      return false;
    }
    WordNode that = node;
    return stringValue == that.stringValue;
  }
  
  String toString() {
    return stringValue;
  }
}

class NumberNode extends Node {
  
  static const int NUMBER_INT    = 0 << Node.KIND_BITS;
  static const int NUMBER_FLOAT  = 1 << Node.KIND_BITS;
  static const int NUMBER_MASK   = 1 << Node.KIND_BITS;

  final int intValue;      // Int
  final double floatValue; // Float
  
  const NumberNode.int(this.intValue)
      : floatValue = 0.0, super(NUMBER_INT | Node.KIND_NUMBER);

  const NumberNode.float(this.floatValue)
      : intValue = 0, super(NUMBER_FLOAT | Node.KIND_NUMBER);
  
  bool operator ==(Object node) {
    if (!(node is NumberNode)) {
      return false;
    }
    NumberNode that = node;
    if (isInt()) {
      return that.isInt() && getIntValue() == that.getIntValue();
    } else if (isFloat()) {
      return that.isFloat() && getFloatValue() == that.getFloatValue();
    }
    throw new Exception("neither int nor float");
  }
  
  bool isInt() { return (tag & NUMBER_MASK) == NUMBER_INT; }
  bool isFloat() { return (tag & NUMBER_MASK) == NUMBER_FLOAT; }
  
  int getIntValue() {
    return intValue;  // truncate float?
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

  String toString() {
    return isFloat() ? getFloatValue().toString() : getIntValue().toString();
  }
}

class DefnNode extends Node {
  
  final String name;
  final ListNode vars;
  final ListNode body;
  
  int get arity => vars.length;
  
  DefnNode(this.name, this.vars, this.body)
      : super(Node.KIND_DEFN);

  bool operator ==(node) {
    if (!(node is DefnNode)) {
      return false;
    }
    DefnNode that = node;
    return name == that.name && body == that.body;
  }
  
  String toString() {
    return "Defn(${name},${vars},${body})";
  }
}



