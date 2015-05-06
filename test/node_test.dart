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
library nodes;

import 'package:test/test.dart';

part "../lib/primitive.dart";
part "../lib/node.dart";

class NodeTest {

  void run() {
    group("NodeTest", () {
      test("list construction and string", () {
        Node foo = new WordNode("\"foo");
        Node bar = new WordNode("\"bar");
        Node barlist = ListNode.makeList([foo, bar]);
        expect(barlist.toString(), equals("[ \"foo \"bar ]"));
      });
    });
  }
}

void main() {
  new NodeTest().run();
}
