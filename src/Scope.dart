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

/**
 * Simple scope, with pointer to parent.
 */
class Scope {
  final Map<String, Node> symtab;
  final Scope parent;
  
  const Scope(Map<String, Node> this.symtab, [Scope this.parent = null]);
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    Scope scope = this;
    while (scope != null) {
      sb.add(scope.symtab);
      scope = scope.parent;
    }
    return sb.toString();
  }
  
  operator [](x) {
    var t = symtab[x];
    if (t != null || parent == null) {
      return t;
    }
    return parent[x];
  }
  
  void bind(String name, Node defn) {
    symtab[name] = defn;
  }
  
  Scope extend() {
    return new Scope(new Map<String, Node>(), this);
  }
}
