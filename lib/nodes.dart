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
import 'dart:collection';


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

  bool get isWord => (tag & KIND_MASK) == KIND_WORD;
  bool get isList => (tag & KIND_MASK) == KIND_LIST;
  bool get isNum => (tag & KIND_MASK) == KIND_NUMBER;
  bool get isPrim => (tag & KIND_MASK) == KIND_PRIM;
  bool get isDefn => (tag & KIND_MASK) == KIND_DEFN;
}

class ListNode extends Node with IterableMixin<Node> {
  static const int LIST_NIL = 0 << Node.KIND_BITS;
  static const int LIST_CONS = 1 << Node.KIND_BITS;
  static const int LIST_MASK = 1 << Node.KIND_BITS;

  bool get isNil => (tag & LIST_MASK) == LIST_NIL;
  bool get isCons => (tag & LIST_MASK) == LIST_CONS;

  bool operator ==(node) {
    if (!(node is ListNode)) {
      return false;
    }
    ListNode that = node;
    return (isNil && that.isNil) || (head == that.head && tail == that.tail);
  }

  bool contains(node) {
    return !isNil && ((head == node) || tail.contains(node));
  }

  int get hashCode {
    return isNil ? -1 : head.hashCode * 7 + tail.hashCode;
  }

  Iterator<Node> get iterator => new ListNodeIterator(this);

  final Node head;
  final ListNode tail;

  ListNode.nil()
      : head = null,
        tail = null,
        super(LIST_NIL | Node.KIND_LIST);
  ListNode.cons(this.head, this.tail) : super(LIST_CONS | Node.KIND_LIST);

  static final Node NIL = ListNode.nil();

  static Node makeList(List list) {
    var n = NIL;
    while (!list.isEmpty) {
      n = new ListNode.cons(list.removeLast(), n);
    }
    return n;
  }

  int get length => _getLengthIter(0);

  int _getLengthIter(int acc) {
    return isNil ? acc : tail._getLengthIter(1 + acc);
  }

  ListNode getPrefix(int length) {
    return (length <= 0)
        ? this
        : new ListNode.cons(head, tail.getPrefix(length - 1));
  }

  ListNode getSuffix(int length) {
    return (length <= 0) ? this : tail.getSuffix(length - 1);
  }

  ListNode append(ListNode rest) {
    return isNil ? rest : new ListNode.cons(head, tail.append(rest));
  }

  String toString() {
    return isNil ? "[]" : _toStringIter("[");
  }

  String _toStringIter(String acc) {
    return isNil
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
    if (nodes.isNil) {
      throw new Exception();
    }
    return nodes.head;
  }

  bool moveNext() {
    nodes = nodes.tail;
    return !nodes.isNil;
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

  int get hashCode {
    return stringValue.hashCode;
  }

  String toString() {
    return stringValue;
  }
}

class NumberNode extends Node {
  static const int NUMBER_INT = 0 << Node.KIND_BITS;
  static const int NUMBER_FLOAT = 1 << Node.KIND_BITS;
  static const int NUMBER_MASK = 1 << Node.KIND_BITS;

  final int intValue_; // Int
  final double floatValue_; // Float

  const NumberNode.int(this.intValue_)
      : floatValue_ = 0.0,
        super(NUMBER_INT | Node.KIND_NUMBER);

  const NumberNode.float(this.floatValue_)
      : intValue_ = 0,
        super(NUMBER_FLOAT | Node.KIND_NUMBER);

  bool operator ==(Object node) {
    if (!(node is NumberNode)) {
      return false;
    }
    NumberNode that = node;
    if (isInt) {
      return that.isInt && intValue == that.intValue;
    } else if (isFloat) {
      return that.isFloat && floatValue == that.floatValue;
    }
    throw new Exception("neither int nor float");
  }

  int get hashCode {
    return isInt ? intValue.hashCode : floatValue.hashCode;
  }

  bool get isInt => (tag & NUMBER_MASK) == NUMBER_INT;
  bool get isFloat => (tag & NUMBER_MASK) == NUMBER_FLOAT;

  int get intValue => intValue_; // truncate float?

  double get floatValue {
    return isInt ? intValue_.toDouble() : floatValue_;
  }

  num get numValue {
    if (isInt) return intValue_;
    if (isFloat) return floatValue_;
    throw new Exception("neither int nor float");
  }

  String toString() {
    return isFloat ? floatValue.toString() : intValue.toString();
  }
}

class DefnNode extends Node {
  final String name;
  final ListNode vars;
  final ListNode body;

  int get arity => vars.length;

  DefnNode(this.name, this.vars, this.body) : super(Node.KIND_DEFN);

  bool operator ==(node) {
    if (!(node is DefnNode)) {
      return false;
    }
    DefnNode that = node;
    return name == that.name && body == that.body;
  }

  int get hashCode {
    return 5 * name.hashCode + body.hashCode;
  }

  String toString() {
    return "Defn(${name},${vars},${body})";
  }
}

class Primitive extends Node {
  static const APPLY = const Primitive(2, "apply");
  static const BACK = const Primitive(1, "bk", "back");
  static const BUTFIRST = const Primitive(1, "butfirst");
  static const CLEAN = const Primitive(0, "clean");
  static const CLEARSCREEN = const Primitive(0, "cs", "clearscreen");
  static const CLEARTEXT = const Primitive(0, "ct", "cleartext");
  static const CONS = const Primitive(2, "_cons");
  static const CURRENT_TIME_MILLIS = const Primitive(0, "current_time_millis");
  static const SELECT = const Primitive(2, "#", "select");
  static const DRAWTEXT = const Primitive(1, "drawtext");
  static const EDALL = const Primitive(0, "edall");
  static const FALSE = const Primitive(0, "false");
  static const FIRST = const Primitive(1, "first");
  static const FORWARD = const Primitive(1, "fd", "forward");
  static const FPUT = const Primitive(2, "fput");
  static const GPROP = const Primitive(2, "gprop");
  static const GREATERTHAN = const Primitive(2, ">", "greaterthan");
  static const GREATEROREQUAL = const Primitive(2, ">=", "greaterorequal");
  static const HIDETURTLE = const Primitive(0, "ht", "hideturtle");
  static const HELP = const Primitive(0, "help");
  static const HOME = const Primitive(0, "home");
  static const IF = const Primitive(2, "if");
  static const IFELSE = const Primitive(3, "ifelse");
  static const ITEM = const Primitive(2, "item");
  static const LEFT = const Primitive(1, "lt", "left");
  static const LESSTHAN = const Primitive(2, "<", "lessthan");
  static const LESSOREQUAL = const Primitive(2, "<=", "lessorequal");
  static const LOCAL = const Primitive(1, "local");
  static const LPUT = const Primitive(2, "lput");
  static const DIFFERENCE = const Primitive(2, "-", "difference");
  static const MAKE = const Primitive(2, "make");
  static const NIL = const Primitive(0, "_nil");
  static const OUTPUT = const Primitive(1, "op", "output");
  static const PENDOWN = const Primitive(0, "pd", "pendown");
  static const PENUP = const Primitive(0, "pu", "penup");
  static const PI = const Primitive(0, "pi");
  static const PLIST = const Primitive(1, "plist");
  static const POWER = const Primitive(2, "^", "power");
  static const PPROP = const Primitive(3, "pprop");
  static const PRODUCT = const Primitive(2, "*", "product");
  static const PRINT = const Primitive(1, "pr", "print");
  static const QUOTE = const Primitive(1, "quote");
  static const QUOTIENT = const Primitive(2, "/", "quotient");
  static const REMAINDER = const Primitive(2, "%", "remainder");
  static const REMPROP = const Primitive(2, "remprop");
  static const REPEAT = const Primitive(2, "repeat");
  static const RIGHT = const Primitive(1, "rt", "right");
  static const RUN = const Primitive(1, "run");
  static const SETPENCOLOR = const Primitive(1, "setpc", "setpencolor");
  static const SETFONT = const Primitive(1, "setfont");
  static const SETTEXTALIGN = const Primitive(1, "settextalign");
  static const SETTEXTBASELINE = const Primitive(1, "settextbaseline");
  static const STOP = const Primitive(0, "stop");
  static const SUM = const Primitive(2, "+", "sum");
  static const THING = const Primitive(1, "thing");
  static const TRACE = const Primitive(1, "trace");
  static const TRUE = const Primitive(0, "true");
  static const TURTLE_GET_STATE = const Primitive(0, "turtlegetstate");
  static const SHOWTURTLE = const Primitive(0, "st", "showturtle");

  static const UNIT = const Primitive(0, "unit");
  static const UNTRACE = const Primitive(1, "untrace");

  static const EMPTYP = const Primitive(1, "emptyp");
  static const EQUALS = const Primitive(2, "==", "equals");
  static const LISTP = const Primitive(1, "listp");
  static const MEMBERP = const Primitive(2, "memberp");
  static const NUMP = const Primitive(1, "nump");
  static const WORDP = const Primitive(1, "wordp");

  static Map<String, Node> makeTopLevel() {
    Map<String, Node> map = new Map();
    for (String k in getBuiltIns().keys) {
      map[k] = getBuiltIns()[k];
    }
    return map;
  }

  static const List<Primitive> commandsList = const [
    BACK,
    CLEAN,
    CLEARSCREEN,
    CLEARTEXT,
    CONS,
    DRAWTEXT,
    EDALL,
    FORWARD,
    HELP,
    HIDETURTLE,
    HOME,
    IF,
    IFELSE,
    LOCAL,
    LEFT,
    MAKE,
    NIL,
    PENDOWN,
    PENUP,
    PPROP,
    PRINT,
    REMPROP,
    REPEAT,
    RIGHT,
    SETFONT,
    SETPENCOLOR,
    SETTEXTALIGN,
    SETTEXTBASELINE,
    SHOWTURTLE,
    STOP,
    TRACE,
    TURTLE_GET_STATE,
    UNTRACE
  ];

  static const List<Primitive> operatorList = const [
    APPLY,
    BUTFIRST,
    CURRENT_TIME_MILLIS,
    DIFFERENCE,
    SELECT,
    FALSE,
    FPUT,
    LESSOREQUAL,
    LESSTHAN,
    FIRST,
    GPROP,
    GREATEROREQUAL,
    GREATERTHAN,
    ITEM,
    LPUT,
    OUTPUT,
    PLIST,
    PRODUCT,
    QUOTE,
    QUOTIENT,
    POWER,
    PI,
    REMAINDER,
    SUM,
    THING,
    TRUE,
    EMPTYP,
    EQUALS,
    LISTP,
    MEMBERP,
    NUMP,
    WORDP
  ];

  static Map<String, Primitive> commandsMap = null;

  static Primitive lookup(String name) => getBuiltIns()[name];

  static Map<String, Primitive> getBuiltIns() {
    if (commandsMap == null) {
      commandsMap = new Map();
      for (Primitive p in commandsList) {
        commandsMap[p.name] = p;
        if (p.altName != null) {
          commandsMap[p.altName] = p;
        }
      }
      for (Primitive p in operatorList) {
        commandsMap[p.name] = p;
        if (p.altName != null) {
          commandsMap[p.altName] = p;
        }
      }
    }
    return commandsMap;
  }

  final int arity;
  final String name;
  final String altName;

  const Primitive(int this.arity, String this.name,
      [String this.altName = null])
      : super(Node.KIND_PRIM);

  bool get needsLazyEval =>
      this == Primitive.IF ||
      this == Primitive.IFELSE ||
      this == Primitive.REPEAT;

  int get precedence {
    switch (this) {
      case GREATERTHAN:
      case GREATEROREQUAL:
      case LESSTHAN:
      case LESSOREQUAL:
      case EQUALS:
        return 5;
      case SUM:
      case DIFFERENCE:
        return 10;
      case REMAINDER:
      case PRODUCT:
      case QUOTIENT:
        return 20;
      case POWER:
        return 30;
      case SELECT:
        return 50;
      default:
        return 0;
    }
  }

  bool get isLeftAssoc {
    switch (this) {
      case SELECT:
      case SUM:
      case DIFFERENCE:
      case PRODUCT:
      case REMAINDER:
      case QUOTIENT:
        return true;
      default:
        return false;
    }
  }

  String toString() => name;
}
