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
library interpreter;

import 'dart:math' as math;

import 'console.dart';
import 'debug.dart';
import 'nodes.dart';
import 'parser.dart';
import 'scope.dart';
import 'turtle.dart';

/**
 * Something went wrong. TODO: useful messaging
 */
class InterpreterException {
  final String message;
  const InterpreterException(this.message);
}

/**
 * Used for OUTPUT and STOP.
 */
class InterpreterOutputException {
  final Node result;
  const InterpreterOutputException(this.result);
}

abstract class InterpreterInterface {
  void interpret(String code);
}

class InterpreterProxy extends InterpreterInterface {

  InterpreterInterface delegate;

  InterpreterProxy();
  
  void init(InterpreterInterface delegate) {
    this.delegate = delegate;
  }
  
  void interpret(String code) { delegate.interpret(code); }
}

class InterpreterState {
  final Set<String> traced;
  
  InterpreterState() : traced = new Set<String>();
  
  bool isTraced(String name) {
    return traced.contains(name);
  }
  
  void trace(String name) {
    traced.add(name);
  }
  
  void untrace(String name) {
    traced.remove(name);
  }
}

class InterpreterImpl extends InterpreterInterface {
  
  final Scope globalScope;
  final Parser parser;
  final Debug debug;
  final TurtleWorker turtle;
  final Console console;
  InterpreterState state;
  
  factory InterpreterImpl(Debug debug, TurtleWorker turtle, Console console) {
    InterpreterImpl impl = new InterpreterImpl.internal(
        new Scope(Primitive.makeTopLevel()), debug, turtle, console);
    debug.log("constructed Interpreter");
    return impl;
  }
  
  InterpreterImpl.internal(
      Scope globalScope, this.debug, this.turtle, this.console)
      : this.globalScope = globalScope,
        state = new InterpreterState(),
        parser = new Parser(globalScope.symtab) {
  }
    
  static WordNode deref(WordNode word, Scope scope) {
    if (scope == null) {
      return word;
    }
    WordNode lookup = scope[word.stringValue];
    return deref(lookup, scope);
  }
  
  // Entry point.
  void interpret(String code) {
    ListNode nodes;   
    try {
      nodes = parser.parse(code);
    } on ParseException catch (ex) {
      console.receive({"exception": ex.message});
      return;
    }
    // debug.log("parsed code $nodes");
    // no parse error, 
    List<Node> nonDefnNodes = [];
    for (Node n in nodes) {
      if (n.isDefn) {
        DefnNode defn = n;        
        define(defn);
      } else {
        nonDefnNodes.add(n);
      }
    }
    ListNode nodesToEval = ListNode.makeList(nonDefnNodes);
    try {
      evalSequence(nodesToEval);      
    } on InterpreterException catch (ex) {
      console.receive({"exception": ex.message});
    } on Exception catch (ex) {
      console.receive({"exception": ex.toString()});
    }
  }
  
  Node evalBinCmp(p, NumberNode op1, NumberNode op2, ListNode nodes, cmpNum(num x, num y)) {
    Node res = cmpNum(op1.numValue, op2.numValue) ? Primitive.TRUE : Primitive.FALSE;
    return new ListNode.cons(res, nodes);
  }
    
  Node evalBinOp(p, NumberNode op1, NumberNode op2, ListNode nodes, opInt(int x, int y), opFloat(double x, double y)) {   
    Node res;
    if (op1.isInt && op2.isInt) {
       res = new NumberNode.int(opInt(op1.intValue, op2.intValue));
    } else {
      res = new NumberNode.float(opFloat(op1.floatValue, op2.floatValue));
    }  
    return new ListNode.cons(res, nodes);
  }
  
  static int primSumInt(int a, int b) => a + b;
  static double primSumFloat(double a, double b) => a + b;
  static int primDifferenceInt(int a, int b) => a - b;
  static double primDifferenceFloat(double a, double b) => a - b;
  static int primProductInt(int a, int b) => a * b;
  static double primProductFloat(double a, double b) => a * b;
  static int primRemainderInt(int a, int b) => a % b;
  static double primRemainderFloat(double a, double b) => a % b;
  static int primQuotientInt(int a, int b) => a ~/ b;
  static double primQuotientFloat(double a, double b) => a / b;

  static bool primEqualsNum(num a, num b) => a == b;
  static bool primLessThanNum(num a, num b) => a < b;
  static bool primLessOrEqualNum(num a, num b) => a <= b;
  static bool primGreaterThanNum(num a, num b) => a > b;
  static bool primGreaterOrEqualNum(num a, num b) => a >= b;

  NumberNode ensureNum(Node node) {
    if (!node.isNum) {
      throw new InterpreterException("expected number");
    }
    return node;
  }
  
  WordNode ensureWord(Node node) {
    if (!node.isWord) {
      throw new InterpreterException("expected word"); 
    }
    return node;
  }
  
  ListNode ensureList(Node node) {
    if (!node.isList) {
      throw new InterpreterException("expected list");
    }  
    return node;
  }

  // Round to the last two digits.
  double trunc(double src) {
    return (100 * src).round() / 100;
  }

  /**
   * Evaluates a primitive function (aka command/operator).
   * 
   * Evaluates the primitive function [p] with (yet unevaluated) arguments
   * available in [nodes]. Returns the (uninterpreted) tail.
   */
  ListNode evalPrimFun(Primitive p, ListNode nodes, Scope scope) {
    if (p == Primitive.QUOTE) {
      return nodes;
    }
    var args = [];
    if (!p.needsLazyEval) {
      for (int i = 0; i < p.arity; ++i) {
        if (nodes.isNil) {
          throw new InterpreterException("not enough inputs to $p");
        }
        nodes = evalInScope(nodes, scope);
        args.add(nodes.head);
        nodes = nodes.tail;
      }
    }
    switch (p) {
      case Primitive.APPLY:
        Node fn = args[0];
        Node fnargs = args[1];
        if (fn.isPrim) {
          return new ListNode.cons(evalPrimFun(fn, fnargs, scope), nodes);
        } else if (fn.isList) {
          Node result = applyTemplate(fn, fnargs, scope);
          return new ListNode.cons(result, nodes);
        }
        break;

      case Primitive.UNIT:
        break;
        
        // turtle 0-arg

      case Primitive.DRAWTEXT:
        WordNode wn = ensureWord(args[0]);
        turtle.receive(p, [wn.stringValue]);
        break;

      case Primitive.CLEAN:
      case Primitive.CLEARSCREEN:
      case Primitive.HIDETURTLE:
      case Primitive.HOME:
      case Primitive.PENDOWN:  
      case Primitive.PENUP:  
      case Primitive.SHOWTURTLE:
        turtle.receive(p, []);
        break;

      case Primitive.TURTLE_GET_STATE:
        var turtleState = turtle.state;
        var stateObject = ListNode.makeList([
            new WordNode('"x'), new NumberNode.float(trunc(turtleState.x)),
            new WordNode('"y'), new NumberNode.float(trunc(turtleState.y)),
            new WordNode('"heading'), new NumberNode.float(
                trunc(turtleState.heading))]);
        return new ListNode.cons(stateObject, nodes);
        // turtle 1-arg

      case Primitive.BACK:
        NumberNode wn = ensureNum(args[0]);
        turtle.receive(p, [wn.numValue]);
        break;  
        
      case Primitive.RIGHT:
        NumberNode nn = ensureNum(args[0]);
        turtle.receive(p, [nn.numValue]);
        break;

      case Primitive.SETFONT:
      case Primitive.SETTEXTALIGN:
      case Primitive.SETTEXTBASELINE:
        // TODO: list
        WordNode wn = ensureWord(args[0]);
        turtle.receive(p, [wn.stringValue]);
        break;
        
      case Primitive.SETPENCOLOR:
        NumberNode nn = ensureNum(args[0]);
        if (!nn.isInt) {
          throw new InterpreterException("invalid color code ${nn.numValue}");
        }
        turtle.receive(p, [nn.intValue]);
        break;
        
      case Primitive.FORWARD:
        NumberNode nn = ensureNum(args[0]);
        turtle.receive(p, [nn.numValue]);
        break;

      case Primitive.LEFT:
        NumberNode nn = ensureNum(args[0]);
        turtle.receive(p, [nn.numValue]);
        break;
        
        // end turtle commands
        
        // begin console commands
        
      case Primitive.CLEARTEXT:
      case Primitive.EDALL:
      case Primitive.HELP:
        console.receive([p.name]);
        break;
        
      case Primitive.PRINT:
        Node n = args[0];
        console.receive([p.name, n.toString()]);
        break;
        
        // end console commands

      case Primitive.BUTFIRST:
        Node arg = args[0];
        if (arg.isWord) {
          var butfirst = (arg as WordNode).stringValue.substring(1);
          return new ListNode.cons(new WordNode(butfirst), nodes);
        } else if (arg.isList) {
          var butfirst = (arg as ListNode).tail;
          return new ListNode.cons(butfirst, nodes);
        }
        throw new InterpreterException("butfirst expected word or list");
      case Primitive.EQUALS:
        // TODO equality for words, lists
        return evalBinCmp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primEqualsNum);
        
      case Primitive.FALSE:
        return new ListNode.cons(p, nodes);

      case Primitive.FIRST:
        Node arg = args[0];
        if (arg.isWord) {
          var first = (arg as WordNode).stringValue.substring(0, 1);
          return new ListNode.cons(new WordNode(first), nodes);
        } else if (arg.isList) {
          var first = (arg as ListNode).head;
          return new ListNode.cons(first, nodes);
        }
        throw new InterpreterException("first expected word or list");

      case Primitive.FPUT:
        Node first = args[0];
        ListNode ln = ensureList(args[1]);
        return new ListNode.cons(new ListNode.cons(first, ln), nodes);
        
      case Primitive.IF:
        nodes = evalInScope(nodes, scope);
        if (!(nodes.head is Primitive)) {
          throw new InterpreterException("expected boolean value, found ${nodes.head}");
        }
        Primitive cond = nodes.head;
        nodes = nodes.tail;
        Node result;
        if (cond == Primitive.TRUE) {
          Node thenPart = nodes.head;
          if (!thenPart.isList) {
            thenPart = new ListNode.cons(thenPart, ListNode.NIL);
          }
          result = evalSequenceInScope(thenPart, scope);
        } else if (cond == Primitive.FALSE) {
          result = Primitive.UNIT;
        } else { 
          throw new InterpreterException("expected boolean");
        }
        nodes = nodes.tail;
        return new ListNode.cons(result, nodes);
        
      case Primitive.IFELSE:
        nodes = evalInScope(nodes, scope);
        Primitive cond = nodes.head;
        nodes = nodes.tail;
        Node result;
        if (cond == Primitive.TRUE) {
          Node thenPart = nodes.head;
          nodes = nodes.tail;
          if (!thenPart.isList) {
            thenPart = new ListNode.cons(thenPart, ListNode.NIL);
          }
          result = evalSequenceInScope(thenPart, scope);
          nodes = nodes.tail;
        } else if (cond == Primitive.FALSE) {
          nodes = nodes.tail;
          Node elsePart = nodes.head;
          nodes = nodes.tail;
          if (!elsePart.isList) {
            elsePart = new ListNode.cons(elsePart, ListNode.NIL);
          }
          result = evalSequenceInScope(elsePart, scope);
        } else { 
          throw new InterpreterException("expected boolean");
        }
        
        return new ListNode.cons(result, nodes);
     
      case Primitive.ITEM:
        Node index = args[0];
        if (!index.isNum || !(index as NumberNode).isInt) {
          throw new InterpreterException("item expected int as first arg");
        }
        // ITEM uses 1-indexed addressing
        int intIndex = (index as NumberNode).intValue - 1;
        if (intIndex < 0) {
          throw new InterpreterException("item expected positive non-zero int");
        }
        Node arg = args[1];
        if (arg.isWord) {
          
          var item = (arg as WordNode)
              .stringValue
              .substring(intIndex, intIndex + 1);
          return new ListNode.cons(new WordNode(item), nodes);
        } else if (arg.isList) {
          var item = (arg as ListNode).getSuffix(intIndex).head;
          return new ListNode.cons(item, nodes);
        }
        throw new InterpreterException("first expected word or list");

      case Primitive.LPUT:
        Node last = args[0];
        ListNode ln = ensureList(args[1]);
        ListNode result = ln.append(ListNode.makeList([last]));
        return new ListNode.cons(result, nodes);
           
      case Primitive.LOCAL:
        WordNode word = ensureWord(args[0]);
        scope.defineLocal(word.stringValue);
        return new ListNode.cons(Primitive.UNIT, nodes);

      case Primitive.MAKE:
        WordNode varRefWord = ensureWord(args[0]);
        Node value = args[1];
        scope.assign(varRefWord.stringValue, value);
        return new ListNode.cons(Primitive.UNIT, nodes);
        
      case Primitive.QUOTE:
        return nodes;

      case Primitive.PI:
        return new ListNode.cons(new NumberNode.float(math.PI), nodes);
        
      case Primitive.REPEAT:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode nn = nodes.head;
        nodes = nodes.tail;
        int times = nn.numValue;
        Node body = nodes.head;
        // Coercing single argument into list. TODO(bqe): error prone, remove.
        if (!body.isList) {
          body = new ListNode.cons(body, ListNode.NIL);
        }
        nodes = nodes.tail;
        for (int i = 0; i < times; ++i) {
          evalSequenceInScope(body, scope);  // ignore result
        }
        break;
        
      case Primitive.THING:
        WordNode wordNode = ensureWord(args[0]);
        Node lookup = scope[wordNode.stringValue];
        if (lookup == null) {
          throw new InterpreterException("no value for: ${wordNode.stringValue}");
        }
        return new ListNode.cons(lookup, nodes);
        
      case Primitive.RUN:
        ListNode list = ensureList(args[0]);
        return new ListNode.cons(evalSequenceInScope(list, scope), nodes.tail);
      
      case Primitive.TRUE:
        return new ListNode.cons(p, nodes);
      
      // math
        
      case Primitive.SUM:
        return evalBinOp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primSumInt, primSumFloat);
 
      case Primitive.DIFFERENCE:
        return evalBinOp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primDifferenceInt, primDifferenceFloat);
      
      case Primitive.PRODUCT:
        return evalBinOp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primProductInt, primProductFloat);

      case Primitive.REMAINDER:
        return evalBinOp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primRemainderInt, primRemainderFloat);

      case Primitive.QUOTIENT:
        return evalBinOp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primQuotientInt, primQuotientFloat);

      case Primitive.GREATERTHAN:
        return evalBinCmp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primGreaterThanNum);

      case Primitive.GREATEROREQUAL:
        return evalBinCmp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primGreaterOrEqualNum);

      case Primitive.LESSTHAN:
        return evalBinCmp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primLessThanNum);
      
      case Primitive.LESSOREQUAL:
        return evalBinCmp(p, ensureNum(args[0]), ensureNum(args[1]), nodes, primLessOrEqualNum);

      // control
        
      case Primitive.STOP:
        throw new InterpreterOutputException(Primitive.UNIT);
     
      case Primitive.OUTPUT:
        Node head = args[0];
        throw new InterpreterOutputException(head);

      case Primitive.TRACE:
        WordNode head = ensureWord(args[0]);
        Node n = scope[head.stringValue];
        if (n != null && n.isDefn) {
          DefnNode defn = n;
          state.trace(defn.name);
        }
        break;
        
      case Primitive.UNTRACE:
        WordNode head = ensureWord(args[0]);
        Node n = scope[head.stringValue];
        if (n != null && n.isDefn) {
          DefnNode defn = n;
          state.untrace(defn.name);           
        }
        break;

      default:
        throw new InterpreterException("not implemented: $p");
    }  
    return new ListNode.cons(Primitive.UNIT, nodes);
  }
  
  /**
   * Interprets template in lambda form 
   *
   * @param defn definition
   */ 
  Node applyTemplate(ListNode fn, ListNode args, Scope scope) {
    ListNode formalParams = fn.head;
    Node body = fn.tail;
    int numFormals = formalParams.length;
    Map<String, Node> env = new Map();
    if (args.length != numFormals) {
      throw new InterpreterException(
          "expected arguments ${numFormals}"
          + "actual arguments: ${args.length}");
    }
    while (numFormals != 0) {
      WordNode formalParam = formalParams.head;
      formalParams = formalParams.tail;
      Node actualParam = args.head;
      args = args.tail;
      env[formalParam.stringValue] = actualParam;
      --numFormals;
    }
    // return body and environment;
    scope = new Scope(env, scope);
    Node result;
    try {
      result = evalSequenceInScope(body, scope);
    } on InterpreterOutputException catch (e) {
      return e.result;
    }
    return result;
  }
  
  /**
   * Interprets user-defined function (aka command/operator).
   *
   * @param defn definition
   */ 
  ListNode applyUserFun(DefnNode defn, ListNode tail, Scope scope) {
    ListNode formalParams = defn.vars;
    ListNode body = defn.body;
    Map<String, Node> env = new Map();
    bool traced = state.isTraced(defn.name);
    StringBuffer trace;
    if (traced) {
      trace = new StringBuffer();
      trace.write(defn.name);
    }
    while (!formalParams.isNil) {
      WordNode formalParam = formalParams.head;
      formalParams = formalParams.tail;
      
      // Evaluate next arg, consuming a prefix.
      tail = evalInScope(tail, scope);
      Node actualParam = tail.head;
      tail = tail.tail;

      env[formalParam.stringValue] = actualParam;
      if (traced) {
        trace.write(" ");
        trace.write(actualParam);
      }
    }

    if (traced) {
      console.receive({"trace": trace.toString()});
    }
    scope = new Scope(env, scope);
    Node result;
    try {
      result = evalSequenceInScope(body, scope);
    } on InterpreterOutputException catch (e) {
      return new ListNode.cons(e.result, tail);
    }
    return new ListNode.cons(result, tail);
  }
  
  /**
   * Entry point, evaluates [nodes] and returns result if any.
   * 
   * @return result of operator, or UNIT for command
   */
  Node evalSequence(ListNode nodes) {
    return evalSequenceInScope(nodes, globalScope);
  }
  
  /**
   * Entry point, defines [node], which must be a DefnNode.
   * 
   * @return result of operator, or UNIT for command
   */
  void define(DefnNode defn) {
    globalScope.bind(defn.name, defn);
    console.receive({"defined": defn.name});
  }
  
  /**
   * Evaluates all commands in [nodes].
   *
   * @return result of last command, or UNIT if `nodes' was empty
   */
  Node evalSequenceInScope(ListNode nodes, Scope scope) {
    Node result;
    while (!nodes.isNil) {
      nodes = evalInScope(nodes, scope);
      result = nodes.head;
      nodes = nodes.tail;
    }
    if (result == null) {  // empty input nodes
      result = Primitive.UNIT;
    }
    return result;
  }
  
  /**
   * Evaluates [nodes] in scope [scope].
   * 
   * @return [result] ++ suffix of unused nodes
   */
  ListNode evalInScope(ListNode nodes, Scope scope) {
    if (nodes.isNil) {
      return nodes;
    }
    Node head = nodes.head;
    ListNode tail = nodes.tail;
    
    if (head.isList) {
      return nodes;
    }
    
    if (head.isNum) {
      return nodes;
    }
    
    // ?
    if (head.isWord && (head as WordNode).stringValue.startsWith("\"")) {
      return nodes;
    }
    
    if (head.isPrim) {
      return evalPrimFun(head, tail, scope);
    }

    if (head.isWord) {
      WordNode word = head;
      Node lookup = scope[word.stringValue];
      if (lookup == null) {
        throw new InterpreterException(
            "I don't know how to ${word.stringValue}");
      }
      if (lookup.isDefn) {
        DefnNode defn = lookup;
        return applyUserFun(defn, tail, scope);
      }
      return new ListNode.cons(lookup, tail);
    }
    
    throw new InterpreterException("I don't know how to ${head}");  
  }
}
