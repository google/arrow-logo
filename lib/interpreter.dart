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

InterpreterWorker interpreterWorker;

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

class InterpreterWorker extends InterpreterInterface {
  
  final Debug debug;
  final Scope globalScope;
  Interpreter interpreter;

  InterpreterWorker(this.debug, TurtleWorker turtle, Console console)
      : globalScope = new Scope(Primitive.makeTopLevel()) {
    interpreter = new Interpreter(globalScope, debug, turtle, console);
    debug.log("constructed InterpreterProcess");
  }
  
  void interpret(String code) {
    interpreter.interpret(code);
  }
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

class Interpreter {
  
  final Scope globalScope;
  final Parser parser;
  final Debug debug;
  final TurtleWorker turtle;
  final Console console;
  InterpreterState state;
  
  Interpreter(Scope globalScope, this.debug, this.turtle, this.console)
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
      if (n.isDefn()) {
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
  
  Node evalBinCmp(ListNode nodes, Scope scope, cmpNum(num x, num y)) {
    nodes = evalInScope(nodes, scope);
    Node op1 = nodes.head;
    if (!(op1.isNum())) {
      throw new InterpreterException("expected num for op1 was ${op1}");
    }
    NumberNode op1node = op1;
    num op1num = op1node.getNumValue();
    nodes = nodes.tail;
    nodes = evalInScope(nodes, scope);
    Node op2 = nodes.head;
    if (!(op2.isNum())) {
      throw new InterpreterException("expected num for op2 was ${op2}");
    }
    NumberNode op2node = op2;
    num op2num = op2node.getNumValue();
    nodes = nodes.tail;
    Node res = cmpNum(op1num, op2num) ? Primitive.TRUE : Primitive.FALSE;
    return new ListNode.cons(res, nodes);
  }
    
  Node evalBinOp(ListNode nodes, Scope scope, opInt(int x, int y), opFloat(double x, double y)) {   
    ListNode nodes1 = evalInScope(nodes, scope);
    Node op1 = nodes1.head;
    if (!(op1.isNum())) {
      throw new InterpreterException("expected num for op1 was ${op1}");
    }
    NumberNode op1num = op1;
    nodes = nodes1.tail;
    nodes = evalInScope(nodes, scope);
    Node op2 = nodes.head;
    if (!(op2.isNum())) {
      throw new InterpreterException("expected num for op2 was ${op2}");
    }
    NumberNode op2num = op2;
    nodes = nodes.tail;
    Node res;
    if (op1num.isInt() && op2num.isInt()) {
       res = new NumberNode.int(opInt(op1num.getIntValue(), op2num.getIntValue()));
    } else {
      res = new NumberNode.float(opFloat(op1num.getFloatValue(), op2num.getFloatValue()));
    }  
    return new ListNode.cons(res, nodes);
  }
  
  static int primSumInt(int a, int b) => a + b;
  static double primSumFloat(double a, double b) => a + b;
  static int primDifferenceInt(int a, int b) => a - b;
  static double primDifferenceFloat(double a, double b) => a - b;
  static int primProductInt(int a, int b) => a * b;
  static double primProductFloat(double a, double b) => a * b;
  static int primQuotientInt(int a, int b) => a ~/ b;
  static double primQuotientFloat(double a, double b) => a / b;

  static bool primEqualsNum(num a, num b) => a == b;
  static bool primLessThanNum(num a, num b) => a < b;
  static bool primLessOrEqualNum(num a, num b) => a <= b;
  static bool primGreaterThanNum(num a, num b) => a > b;
  static bool primGreaterOrEqualNum(num a, num b) => a >= b;

  void ensureNum(Node node) {
    if (!node.isNum()) {
      throw new InterpreterException("expected number");
    }
  }
  
  void ensureWord(Node node) {
    if (!node.isWord()) {
      throw new InterpreterException("expected word"); 
    }
  }
  
  void ensureList(Node node) {
    if (!node.isList()) {
      throw new InterpreterException("expected list");
    }  
  }

  /**
   * Evaluates a primitive function (aka command/operator).
   * 
   * @return uninterpreted tail
   */
  ListNode evalPrimFun(Primitive p, ListNode nodes, Scope scope) {
    switch (p) {
      case Primitive.APPLY:
        nodes = evalInScope(nodes, scope);
        Node fn = nodes.head;
        nodes = evalInScope(nodes.tail, scope);
        Node args = nodes.head;
        nodes = nodes.tail;
        if (fn.isPrim()) {
          return new ListNode.cons(evalPrimFun(fn, args, scope), nodes);
        } else if (fn.isList()) {
          Node result = applyTemplate(fn, args, scope);
          return new ListNode.cons(result, nodes);
        }
        break;

      case Primitive.UNIT:
        break;
        
        // turtle 0-arg

      case Primitive.CLEAN:
      case Primitive.CLEARSCREEN:
      case Primitive.HIDETURTLE:
      case Primitive.HOME:
      case Primitive.PENDOWN:  
      case Primitive.PENUP:  
      case Primitive.SHOWTURTLE:
        turtle.receive([p.name]);
        break;

        // turtle 1-arg

      case Primitive.BACK:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode wn = nodes.head;
        nodes = nodes.tail;
        turtle.receive([p.name, wn.getNumValue()]);
        break;  
        
      case Primitive.RIGHT:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode nn = nodes.head;
        nodes = nodes.tail;
        turtle.receive([p.name, nn.getNumValue()]);
        break;
        
      case Primitive.SETPENCOLOR:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode nn = nodes.head;
        nodes = nodes.tail;
        if (!nn.isInt()) {
          throw new InterpreterException("invalid color code ${nn.getNumValue()}");
        }
        turtle.receive([p.name, nn.getIntValue()]);
        break;
        
      case Primitive.FORWARD:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode wn = nodes.head;
        nodes = nodes.tail;
        turtle.receive([p.name, wn.getNumValue()]);
        break;

      case Primitive.LEFT:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode wn = nodes.head;
        nodes = nodes.tail;
        turtle.receive([p.name, wn.getNumValue()]);
        break;
        
        // end turtle commands
        
        // begin console commands
        
      case Primitive.CLEARTEXT:
      case Primitive.EDALL:
      case Primitive.HELP:
        console.receive([p.name]);
        break;
        
      case Primitive.PRINT:
        nodes = evalInScope(nodes, scope);
        Node n = nodes.head;
        nodes = nodes.tail;
        console.receive([p.name, n.toString()]);
        break;
        
        // end console commands
      case Primitive.EQUALS:
        // TODO equality for words, lists
        return evalBinCmp(nodes, scope, primEqualsNum);
        
      case Primitive.FALSE:
        return new ListNode.cons(p, nodes);

      case Primitive.FPUT:
        nodes = evalInScope(nodes, scope);
        Node first = nodes.head;
        nodes = evalInScope(nodes.tail, scope);
        ensureList(nodes.head);
        ListNode ln = nodes.head;
        nodes = nodes.tail;
        return new ListNode.cons(new ListNode.cons(first, ln), nodes);
        
      case Primitive.IF:
        nodes = evalInScope(nodes, scope);
        Primitive cond = nodes.head;
        nodes = nodes.tail;
        Node result;
        if (cond == Primitive.TRUE) {
          Node thenPart = nodes.head;
          if (!thenPart.isList()) {
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
          if (!thenPart.isList()) {
            thenPart = new ListNode.cons(thenPart, ListNode.NIL);
          }
          result = evalSequenceInScope(thenPart, scope);
          nodes = nodes.tail;
        } else if (cond == Primitive.FALSE) {
          nodes = nodes.tail;
          Node elsePart = nodes.head;
          nodes = nodes.tail;
          if (!elsePart.isList()) {
            elsePart = new ListNode.cons(elsePart, ListNode.NIL);
          }
          result = evalSequenceInScope(elsePart, scope);
        } else { 
          throw new InterpreterException("expected boolean");
        }
        
        return new ListNode.cons(result, nodes);
      
     
      case Primitive.LPUT:
        nodes = evalInScope(nodes, scope);
        Node last = nodes.head;
        nodes = evalInScope(nodes.tail, scope);
        ensureList(nodes.head);
        ListNode ln = nodes.head;
        nodes = nodes.tail;
        ListNode result = ln.append(ListNode.makeList([last]));
        return new ListNode.cons(result, nodes);
           
      case Primitive.LOCAL:
        nodes = evalInScope(nodes, scope);
        Node name = nodes.head;
        ensureWord(name);
        WordNode word = name;
        nodes = nodes.tail;
        scope.defineLocal(word.stringValue);
        return new ListNode.cons(Primitive.UNIT, nodes);

      case Primitive.MAKE:
        nodes = evalInScope(nodes, scope);
        Node varRef = nodes.head;        
        nodes = nodes.tail;
        ensureWord(varRef);
        WordNode varRefWord = varRef;
        nodes = evalInScope(nodes, scope);
        Node value = nodes.head;
        scope.assign(varRefWord.stringValue, value);
        return new ListNode.cons(Primitive.UNIT, nodes.tail);
        
      case Primitive.PI:
        return new ListNode.cons(new NumberNode.float(math.PI), nodes);
        
      case Primitive.REPEAT:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode nn = nodes.head;
        nodes = nodes.tail;
        int times = nn.getNumValue();
        Node body = nodes.head;
        // Coercing single argument into list. TODO(bqe): error prone, remove.
        if (!body.isList()) {
          body = new ListNode.cons(body, ListNode.NIL);
        }
        nodes = nodes.tail;
        for (int i = 0; i < times; ++i) {
          evalSequenceInScope(body, scope);  // ignore result
        }
        break;
        
      case Primitive.THING:
        Node arg = nodes.head;
        ensureWord(arg);
        WordNode wordNode = arg;
        Node lookup = scope[wordNode.stringValue];
        if (lookup == null) {
          throw new InterpreterException("no value for: ${arg}");
        }
        return new ListNode.cons(lookup, nodes.tail);
        
      case Primitive.RUN:
        Node arg = nodes.head;
        ensureList(arg);
        ListNode list = arg;
        return new ListNode.cons(evalSequenceInScope(list, scope), nodes.tail);
      
      case Primitive.TRUE:
        return new ListNode.cons(p, nodes);
      
      // math
        
      case Primitive.SUM:
        return evalBinOp(nodes, scope, primSumInt, primSumFloat);
 
      case Primitive.DIFFERENCE:
        return evalBinOp(nodes, scope, primDifferenceInt, primDifferenceFloat);
      
      case Primitive.PRODUCT:
        return evalBinOp(nodes, scope, primProductInt, primProductFloat);

      case Primitive.QUOTIENT:
        return evalBinOp(nodes, scope, primQuotientInt, primQuotientFloat);

      case Primitive.GREATERTHAN:
        return evalBinCmp(nodes, scope, primGreaterThanNum);

      case Primitive.GREATEROREQUAL:
        return evalBinCmp(nodes, scope, primGreaterOrEqualNum);

      case Primitive.LESSTHAN:
        return evalBinCmp(nodes, scope, primLessThanNum);
      
      case Primitive.LESSOREQUAL:
        return evalBinCmp(nodes, scope, primLessOrEqualNum);  

      // control
        
      case Primitive.STOP:
        throw new InterpreterOutputException(Primitive.UNIT);
     
      case Primitive.OUTPUT:
        nodes = evalInScope(nodes, scope);
        Node head = nodes.head;
        throw new InterpreterOutputException(head);

      case Primitive.TRACE:
        Node head = nodes.head;
        nodes = nodes.tail;
        
        if (head.isWord()) {
          Node n = scope[(head as WordNode).stringValue];
          if (n != null && n.isDefn()) {
            DefnNode defn = n;
            state.trace(defn.name);
          }
        }
        break;
        
      case Primitive.UNTRACE:
        Node head = nodes.head;
        nodes = nodes.tail;
        if (head.isWord()) {
          Node n = scope[(head as WordNode).stringValue];
          if (n != null && n.isDefn()) {
            DefnNode defn = n;
            state.untrace(defn.name);           
          }
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
    while (!formalParams.isNil()) {
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
      console.send({"trace": trace.toString()});
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
    console.send({"defined": defn.name});
  }
  
  /**
   * Evaluates all commands in [nodes].
   *
   * @return result of last command, or UNIT if `nodes' was empty
   */
  Node evalSequenceInScope(ListNode nodes, Scope scope) {
    Node result;
    while (!nodes.isNil()) {
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
    if (nodes.isNil()) {
      return nodes;
    }
    Node head = nodes.head;
    ListNode tail = nodes.tail;
    
    if (head.isList()) {
      return nodes;
    }
    
    if (head.isNum()) {
      return nodes;
    }
    
    if (head.isWord() && (head as WordNode).stringValue.startsWith("\"")) {
      return nodes;
    }
    
    if (head.isPrim()) {
      return evalPrimFun(head, tail, scope);
    }

    if (head.isWord()) {
      WordNode word = head;
      Node lookup = scope[word.stringValue];
      if (lookup == null) {
        throw new InterpreterException(
            "I don't know how to ${word.stringValue}");
      }
      if (lookup.isDefn()) {
        DefnNode defn = lookup;
        return applyUserFun(defn, tail, scope);
      }
      return new ListNode.cons(lookup, tail);
    }
    
    throw new InterpreterException("I don't know how to ${head}");  
  }
}
