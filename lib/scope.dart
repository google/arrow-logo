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
import 'nodes.dart';

/**
 * Simple scope, with pointer to parent.
 */
class Scope {
  final Map<String, Node> symtab;
  final Scope parent;

  const Scope(Map<String, Node> this.symtab, [Scope this.parent = null]);

  String toString() {
    final sb = new StringBuffer();
    Scope scope = this;
    while (scope != null) {
      sb.write(scope.symtab);
      scope = scope.parent;
    }
    return sb.toString();
  }

  operator [](String name) {
    final t = symtab[name.toLowerCase()];
    if (t != null || parent == null) {
      return t;
    }
    return parent[name];
  }

  void defineLocal(String name) {
    symtab[name.toLowerCase()] = Primitive.UNIT;
  }

  void assign(String name, Node value) {
    final t = symtab[name.toLowerCase()];
    if (t != null || parent == null) {
      symtab[name.toLowerCase()] = value;
      return;
    }
    parent.assign(name, value);
  }

  void bind(String name, Node defn) {
    symtab[name.toLowerCase()] = defn;
  }

  void bindGlobal(String name, Node defn) {
    if (parent == null) {
      symtab[name.toLowerCase()] = defn;
    } else {
      parent.bindGlobal(name, defn);
    }
  }

  Scope extend() {
    return new Scope(new Map<String, Node>(), this);
  }
}
