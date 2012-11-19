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

class NodeTest {
  
  String matchWord(Node n) {
    return match(n).with(
        word(eq("foo")) >> (_) { throw "cannothappen"; }
      | word(v.x)       >> (e) { return e.x; }
      | v.x             >> (_) { return "no"; }
    );
  }
  
  void testBasicMatch() {
    match("foo").with( eq("foo") >> (_) {} );
    match("foo").with( 
        eq("bar") >> (_) { throw "cannothappen"; }
        | v.x     >> (_) { return ""; }
    );
    expect(matchWord(new WordNode("hello")), equals("hello"));
    expect(matchWord(new NumberNode.int(3)), equals("no"));
  }
  
  void testListToString() {
    Node foo = new WordNode("\"foo");
    Node bar = new WordNode("\"bar");
    Node barlist = ListNode.makeList([foo, bar]);
    expect(barlist.toString(), equals("[ \"foo \"bar ]"));
  }
  
  void run() {
    group("NodeTest", () {
      test("basic match", testBasicMatch);
      test("list construction and string", testListToString);
      });
  }
}
