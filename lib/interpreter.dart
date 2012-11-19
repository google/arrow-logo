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
part of arrowlogo;

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

class Interpreter {
  
  final Turtle turtle;
  final Console console;
  final Scope globalScope;
  
  const Interpreter(this.turtle, this.console, this.globalScope);
  
  static WordNode deref(WordNode word, Scope scope) {
    if (scope == null) {
      return word;
    }
    WordNode lookup = scope[word.stringValue];
    return deref(lookup, scope);
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
        
      case Primitive.BACK:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode wn = nodes.head;
        nodes = nodes.tail;
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
        
      case Primitive.EQUALS:
        // TODO equality for words, lists
        return evalBinCmp(nodes, scope, primEqualsNum);
        
      case Primitive.FALSE:
        return new ListNode.cons(p, nodes);
        
      case Primitive.FORWARD:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode wn = nodes.head;
        nodes = nodes.tail;
        turtle.forward(wn.getNumValue()); 
        break;

      case Primitive.FPUT:
        nodes = evalInScope(nodes, scope);
        Node first = nodes.head;
        nodes = evalInScope(nodes.tail, scope);
        ensureList(nodes.head);
        ListNode ln = nodes.head;
        nodes = nodes.tail;
        return new ListNode.cons(new ListNode.cons(first, ln), nodes);

      case Primitive.HELP:
        console.showHelp();
        break;
        
      case Primitive.HOME:
        turtle.home();
        break;
        
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
          result = evalAllInScope(thenPart, scope);
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
          result = evalAllInScope(thenPart, scope);
          nodes = nodes.tail;
        } else if (cond == Primitive.FALSE) {
          nodes = nodes.tail;
          Node elsePart = nodes.head;
          nodes = nodes.tail;
          if (!elsePart.isList()) {
            elsePart = new ListNode.cons(elsePart, ListNode.NIL);
          }
          result = evalAllInScope(elsePart, scope);
        } else { 
          throw new InterpreterException("expected boolean");
        }
        
        return new ListNode.cons(result, nodes);
      
      case Primitive.HIDETURTLE:
        turtle.hideTurtle();
        break;
        
      case Primitive.LEFT:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode wn = nodes.head;
        nodes = nodes.tail;
        turtle.left(wn.getNumValue()); 
        break;
     
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
        
      case Primitive.PRINT:
        nodes = evalInScope(nodes, scope);
        Node n = nodes.head;
        nodes = nodes.tail;
        console.writeln(n.toString());
        break;
        
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
          evalAllInScope(body, scope);  // ignore result
        }
        break;
        
      case Primitive.RIGHT:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode nn = nodes.head;
        nodes = nodes.tail;
        turtle.right(nn.getNumValue());
        break;
        
      case Primitive.SETPENCOLOR:
        nodes = evalInScope(nodes, scope);
        ensureNum(nodes.head);
        NumberNode nn = nodes.head;
        nodes = nodes.tail;
        if (!nn.isInt() || !turtle.setPenColor(nn.getIntValue())) {
          throw new InterpreterException("invalid color code ${nn.getNumValue()}");
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
        
      case Primitive.PENDOWN:
        turtle.penDown();
        break;
        
      case Primitive.PENUP:
        turtle.penUp();
        break;
                
      case Primitive.SHOWTURTLE:
        turtle.showTurtle();
        break;
      
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

      default:
        throw new InterpreterException("not implemented: $p");
    }
    turtle.draw();  
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
          "expected arguments ${numFormals}".concat(
          "actual arguments: ${args.length}"));
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
      result = evalAllInScope(body, scope);
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
    while (!formalParams.isNil()) {
      WordNode formalParam = formalParams.head;
      formalParams = formalParams.tail;
      
      // Evaluate next arg, consuming a prefix.
      tail = evalInScope(tail, scope);
      Node actualParam = tail.head;
      tail = tail.tail;

      env[formalParam.stringValue] = actualParam;
    }
    scope = new Scope(env, scope);
    Node result;
    try {
      result = evalAllInScope(body, scope);
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
  Node eval(ListNode nodes) {
    return evalAllInScope(nodes, globalScope);
  }
  
  /**
   * Evaluates all commands in [nodes].
   *
   * @return result of last command, or UNIT if `nodes' was empty
   */
  Node evalAllInScope(ListNode nodes, Scope scope) {
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
    return match(nodes.head).with(

        // self - evaluating
        
        cons(v.hd, v.tl)
          >> (_) { return nodes; }

      | nil()
          >> (_) { return nodes; }

      | number(v.n)
          >> (_) { return nodes; }

      | word(v.str) & guard((e) => e.str.startsWith("\""))
          >> (_) { return nodes; }

      // call built-in
          
      | prim(v.fn)
          >> (e) { return evalPrimFun(e.fn, nodes.tail, scope); }

        // add definition 
          
      | v.defn % defn(v.name, v.arity, v.body)
          >> (e) {  // TODO(bqe): this does not belong here 
            globalScope.bind(e.name, e.defn);
            return new ListNode.cons(Primitive.UNIT, nodes.tail);
          }
       
        // call user-defined
          
      | word(v.str)
          >> (e) {    
           Node lookup = scope[e.str];
           if (lookup == null) {
             throw new InterpreterException("I don't know how to ${e.str}");
           }
           if (lookup.isDefn()) {
             DefnNode defn = lookup;
             return applyUserFun(defn, nodes.tail, scope);
           }
           return new ListNode.cons(lookup, nodes.tail);
        }
          
      | v.x >> (e) {
          throw new InterpreterException("I don't know how to ${e.x}");
        }
    );  
  }
}
