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

class Primitive extends Node {
 
  static final BACK = const Primitive(1, "back", "bk");
  static final CLEAN = const Primitive(0, "clean");
  static final CLEARSCREEN = const Primitive(0, "cs", "clearscreen");
  static final CONS = const Primitive(2, "_cons"); 
  static final FORWARD = const Primitive(1, "fd", "forward"); 
  static final GREATERTHAN = const Primitive(1, ">", "greaterthan"); 
  static final GREATEROREQUAL = const Primitive(1, ">=", "greaterorequal"); 
  static final HIDETURTLE = const Primitive(0, "ht", "hideturtle");
  static final HOME = const Primitive(0, "home");
  static final LEFT = const Primitive(1, "lt", "left"); 
  static final LESSTHAN = const Primitive(1, "<", "lessthan"); 
  static final LESSOREQUAL = const Primitive(1, "<=", "lessorequal"); 
  static final DIFFERENCE = const Primitive(2, "-", "difference"); 
  static final NIL = const Primitive(0, "_nil"); 
  static final PENDOWN = const Primitive(0, "pd", "pendown"); 
  static final PENUP = const Primitive(0, "pu", "penup"); 
  static final PI = const Primitive(0, "pi");  
  static final POWER = const Primitive(2, "^", "power"); 
  static final PRINT = const Primitive(1, "pr", "print"); 
  static final PRODUCT = const Primitive(2, "*", "product"); 
  static final QUOTIENT = const Primitive(2, "/", "quotient"); 
  static final REPEAT = const Primitive(2, "repeat"); 
  static final RIGHT = const Primitive(1, "rt", "right"); 
  static final SUM = const Primitive(2, "+", "sum"); 
  static final SHOWTURTLE = const Primitive(0, "st", "showturtle");
  
  static final UNIT = const Primitive(0, "unit");
  
  // static final INCOMPLETE = const Primitive(1, "_incomplete");
  
  static final List<Primitive> commandsList = const [ 
    BACK, CLEAN, CLEARSCREEN, CONS, FORWARD, HIDETURTLE, HOME, LEFT, NIL, PENDOWN,
    PENUP, PI, PRINT, REPEAT, RIGHT, SHOWTURTLE ];

  static getPrecedence(Primitive p) {
    switch (p) {
    case GREATERTHAN: 
    case GREATEROREQUAL:
    case LESSTHAN: 
    case LESSOREQUAL:
      return 5;
    case SUM: 
    case DIFFERENCE:
      return 10;
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
    case QUOTIENT:
      return true;
    default:
      return false;
    }
  }
  
  static Map<String, Primitive> commandsMap = null;
  
  static Primitive lookup(String name) => getCommands()[name];

  static Map<String, Primitive> getCommands() {
    if (commandsMap == null) {
      commandsMap = new Map();
      for (Primitive p in commandsList) {
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
  
  String toString() => "Prim($name)";
}