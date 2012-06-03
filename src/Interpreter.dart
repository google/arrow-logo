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

class Interpreter {
  
  final Turtle turtle;
  final Console console;
  final Scope globalScope;
  
  const Interpreter(this.turtle, this.console, this.globalScope);
  
  static WordNode deref(WordNode word, Scope scope) {
    if (scope == null) {
      return word;
    }
    if (!word.isIdent()) {
      return word;
    }
    WordNode lookup = scope[word.getIdentName()];
    return deref(lookup, scope);
  }
  
  Node evalBinOp(ListNode nodes, Scope scope, opInt(int x, int y), opFloat(double x, double y)) {   
    nodes = evalInScope(nodes, scope);
    WordNode op1 = nodes.getHead();
    nodes = nodes.getTail();
    nodes = evalInScope(nodes, scope);
    WordNode op2 = nodes.getHead();
    nodes = nodes.getTail();
    WordNode res;
    if (op1.isInt() && op2.isInt()) {
       res = WordNode.makeInt(opInt(op1.getIntValue(), op2.getIntValue()));
    } else {
      res = WordNode.makeFloat(opFloat(op1.getFloatValue(), op2.getFloatValue()));
    }  
    return ListNode.makeCons(res, nodes);
  }
  
  static int primSumInt(int a, int b) => a + b;
  static double primSumFloat(double a, double b) => a + b;
  static int primDifferenceInt(int a, int b) => a - b;
  static double primDifferenceFloat(double a, double b) => a - b;
  static int primProductInt(int a, int b) => a * b;
  static double primProductFloat(double a, double b) => a * b;
  static int primQuotientInt(int a, int b) => (a / b).toInt();
  static double primQuotientFloat(double a, double b) => a / b;
  
  // @return uninterpreted tail
  ListNode evalPrimCommand(Primitive p, ListNode nodes, Scope scope) {
    switch (p) {
      case Primitive.UNIT:
        break;
      case Primitive.BACK:
        WordNode wn = nodes.getHead();
        nodes = nodes.getTail();
        turtle.back(wn.getNumValue());
        break;
      case Primitive.CLEAN:
        turtle.clean();
        break;
      case Primitive.CLEARSCREEN:
        turtle.clean();
        turtle.home();
        break;
      case Primitive.CLEARTEXT:
        console.clearText();
        break;
      case Primitive.FORWARD:
        nodes = evalInScope(nodes, scope);
        WordNode wn = nodes.getHead();
        nodes = nodes.getTail();
        turtle.forward(wn.getNumValue()); 
        break;
      case Primitive.HELP:
        console.showHelp();
        break;
      case Primitive.HOME:
        turtle.home();
        break;
      case Primitive.HIDETURTLE:
        turtle.hideTurtle();
        break;
      case Primitive.LEFT:
        nodes = evalInScope(nodes, scope);
        WordNode wn = nodes.getHead();
        nodes = nodes.getTail();
        turtle.left(wn.getNumValue()); 
        break;
        
      case Primitive.PI:
        return ListNode.makeCons(WordNode.makeFloat(Math.PI), nodes);
        
      case Primitive.PRINT:
        nodes = evalInScope(nodes, scope);
        WordNode wn = nodes.getHead();
        nodes = nodes.getTail();
        // TODO: pretty-print values
        console.writeln(wn.toString());
        break;
        
      case Primitive.REPEAT:
        nodes = evalInScope(nodes, scope);
        WordNode wn = nodes.getHead();
        nodes = nodes.getTail();
        int times = wn.getNumValue();
        Node body = nodes.getHead();
        if (!body.isList()) {
          body = ListNode.makeCons(body, ListNode.makeNil());
        }
        nodes = nodes.getTail();
        for (int i = 0; i < times; ++i) {
          evalAllInScope(body, scope);  // ignore result
        }
        break;
      case Primitive.RIGHT:
        nodes = evalInScope(nodes, scope);
        WordNode wn = nodes.getHead();
        nodes = nodes.getTail();
        turtle.right(wn.getNumValue());
        break;
      case Primitive.PENDOWN:
        turtle.penDown();
        break;
      case Primitive.PENUP:
        turtle.penUp();
        break;
      case Primitive.SHOWTURTLE:
        turtle.showTurtle();
        break;
        
      case Primitive.SUM:
        return evalBinOp(nodes, scope, primSumInt, primSumFloat);
 
      case Primitive.DIFFERENCE:
        return evalBinOp(nodes, scope, primDifferenceInt, primDifferenceFloat);
      
      case Primitive.PRODUCT:
        return evalBinOp(nodes, scope, primProductInt, primProductFloat);

      case Primitive.QUOTIENT:
        return evalBinOp(nodes, scope, primQuotientInt, primQuotientFloat);

      default:
        throw new Exception("not implemented: $p");
    }
    turtle.draw();  
    return ListNode.makeCons(Primitive.UNIT, nodes);
  }
  
  // interpret user-defined command.
  // @param defn definition
  ListNode evalUserCommand(WordNode defn, ListNode tail, Scope scope) {
    int numParams = defn.getArity();
    ListNode body = defn.getDefnBody();
    Map<String, Node> env = new Map();
    while (numParams != 0) {
      WordNode formalParam = body.getHead();
      assert(formalParam.isIdent());
      Node actualParam = tail.getHead();
      String identName = formalParam.getIdentName();
      body = body.getTail();
      env[formalParam.getIdentName()] = evalInScope(actualParam, scope);
      tail = tail.getTail();
      --numParams;
    }
    if (!env.isEmpty()) {
      scope = new Scope(env, scope);
    }
    Node result = evalAllInScope(body, scope);
    return ListNode.makeCons(result, tail);
  }
  
  // entry point. Evaluates all commands in `nodes' and
  // returns result of last command.
  // @return result of last command, or UNIT if empty
  Node eval(ListNode nodes) {
    return evalAllInScope(nodes, globalScope);
  }
  
  // Evaluates all commands in `nodes'.
  // @return result of last command, or UNIT if `nodes' was empty
  Node evalAllInScope(ListNode nodes, Scope scope) {
    Node result;
    while (!nodes.isNil()) {
      nodes = evalInScope(nodes, scope);
      result = nodes.getHead();
      nodes = nodes.getTail();
    }
    if (result == null) {
      result = Primitive.UNIT;
    }
    return result;
  }
  
  // @return [result] ++ suffix of unused nodes
  ListNode evalInScope(ListNode nodes, Scope scope) {
    if (nodes.isNil()) {
      return nodes;
    }
    Node fn = nodes.getHead();
 
    if (fn.isList()) {
      return nodes;
    }
    
    if (fn.isPrim()) {
      Primitive p = fn;
      return evalPrimCommand(p, nodes.getTail(), scope);
    }
    WordNode wn = fn;
    if (wn.isNum()) {
      return nodes;
    }
    if (wn.isDefn()) {  // new definition
      globalScope.bind(wn.getDefnName(), wn);
      return ListNode.makeCons(Primitive.UNIT, nodes.getTail());
    }
    if (wn.isIdent()) {  // command reference
      Node defn = scope[wn.getIdentName()];
      if (defn == null) {
        throw new Exception("unknown command ${wn.getIdentName()}");
      }
      if (defn.isPrim()) {
        Primitive p = fn;
        return evalPrimCommand(p, nodes.getTail(), scope);
      }
      assert(defn.isWord());
      WordNode dwn = defn;
      assert(dwn.isDefn());
      return evalUserCommand(defn, nodes.getTail(), scope);
    }
    throw new Exception("what's going on here? $wn");
  }
}
