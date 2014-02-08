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

class Primitive extends Node {
 
  static const APPLY = const Primitive(2, "apply");
  static const BACK = const Primitive(1, "bk", "back");
  static const BUTFIRST = const Primitive(1, "butfirst");
  static const CLEAN = const Primitive(0, "clean");
  static const CLEARSCREEN = const Primitive(0, "cs", "clearscreen");
  static const CLEARTEXT = const Primitive(0, "ct", "cleartext");
  static const CONS = const Primitive(2, "_cons"); 
  static const EDALL = const Primitive(0, "edall"); 
  static const EQUALS = const Primitive(2, "==", "equals"); 
  static const FALSE = const Primitive(0, "false");
  static const FIRST = const Primitive(1, "first");
  static const FORWARD = const Primitive(1, "fd", "forward"); 
  static const FPUT = const Primitive(2, "fput");
  static const GREATERTHAN = const Primitive(1, ">", "greaterthan"); 
  static const GREATEROREQUAL = const Primitive(1, ">=", "greaterorequal"); 
  static const HIDETURTLE = const Primitive(0, "ht", "hideturtle");
  static const HELP = const Primitive(0, "help");
  static const HOME = const Primitive(0, "home");
  static const IF = const Primitive(2, "if");
  static const IFELSE = const Primitive(3, "ifelse");
  static const ITEM = const Primitive(2, "item");
  static const LEFT = const Primitive(1, "lt", "left"); 
  static const LESSTHAN = const Primitive(1, "<", "lessthan"); 
  static const LESSOREQUAL = const Primitive(1, "<=", "lessorequal"); 
  static const LOCAL = const Primitive(1, "local"); 
  static const LPUT = const Primitive(2, "lput"); 
  static const DIFFERENCE = const Primitive(2, "-", "difference"); 
  static const MAKE = const Primitive(2, "make");
  static const NIL = const Primitive(0, "_nil"); 
  static const OUTPUT = const Primitive(1, "output");
  static const PENDOWN = const Primitive(0, "pd", "pendown"); 
  static const PENUP = const Primitive(0, "pu", "penup"); 
  static const PI = const Primitive(0, "pi");  
  static const POWER = const Primitive(2, "^", "power"); 
  static const PRODUCT = const Primitive(2, "*", "product"); 
  static const PRINT = const Primitive(1, "pr", "print");   
  static const QUOTE = const Primitive(1, "quote");
  static const QUOTIENT = const Primitive(2, "/", "quotient"); 
  static const REMAINDER = const Primitive(2, "%", "remainder");
  static const REPEAT = const Primitive(2, "repeat"); 
  static const RIGHT = const Primitive(1, "rt", "right");
  static const RUN = const Primitive(1, "run");
  static const SETPENCOLOR = const Primitive(1, "setpc", "setpencolor");
  static const STOP = const Primitive(0, "stop");
  static const SUM = const Primitive(2, "+", "sum"); 
  static const THING = const Primitive(1, "thing"); 
  static const TRACE = const Primitive(1, "trace"); 
  static const TRUE = const Primitive(0, "true"); 
  static const TURTLE_GET_STATE = const Primitive(0, "turtlegetstate");
  static const SHOWTURTLE = const Primitive(0, "st", "showturtle");
  
  static const UNIT = const Primitive(0, "unit");
  static const UNTRACE = const Primitive(1, "untrace"); 
  
  static Map<String, Primitive> makeTopLevel() {
    Map<String, Primitive> map = new Map();
    for (String k in getBuiltIns().keys) {
      map[k] = getBuiltIns()[k];
    }
    return map;
  }
  
  static const List<Primitive> commandsList = const [ 
    BACK, CLEAN, CLEARSCREEN, CLEARTEXT, CONS, EDALL, FORWARD, HELP, HIDETURTLE,
    HOME, IF, IFELSE, LOCAL, LEFT, MAKE, NIL, PENDOWN, PENUP, PRINT, REPEAT, RIGHT,
    SETPENCOLOR, SHOWTURTLE, STOP, TRACE, TURTLE_GET_STATE, UNTRACE ];

  static const List<Primitive> operatorList = const [
    APPLY, BUTFIRST, DIFFERENCE, FALSE, FPUT, LESSOREQUAL, LESSTHAN, FIRST,
    GREATEROREQUAL,
    GREATERTHAN, ITEM, LPUT, OUTPUT, PRODUCT, QUOTE, QUOTIENT, POWER, PI,
    REMAINDER,
    SUM, THING, TRUE ];

  static getPrecedence(Primitive p) {
    switch (p) {
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
    default:
      return 0;
    }
  }
  
  static isLeftAssoc(Primitive p) {
    switch (p) {
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
  
  const Primitive(
    int this.arity,
    String this.name,
    [String this.altName = null]) : super(Node.KIND_PRIM);
  
  bool get needsLazyEval =>
    this == Primitive.IF
    || this == Primitive.IFELSE
    || this == Primitive.REPEAT;
  String toString() => name;
}
