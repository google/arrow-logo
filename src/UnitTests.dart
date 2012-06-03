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

// TODO: For some reason, the following import fails.
// Hence, we cannot use any types html.* in source files we want to unit test.
// Type `Dynamic' to the rescue. 

// #import('dart:html', prefix: "html");

#source("Console.dart");
#source("Interpreter.dart");
#source("InterpreterTest.dart");
#source("Node.dart");
#source("Primitive.dart");
#source("Parser.dart");
#source("ParserTest.dart");
#source("Scope.dart");
#source("Turtle.dart");

// Essential methods for unit testing.
class UnitTests {
  
  void assertEquals(Object expected, Object actual) {
    if (expected != actual) {
      throw new Exception("\nexpected $expected\nactual   $actual");
    }
  }

  void assertTrue(bool cond) {
    if (!cond) {
      throw new Exception("condition does not hold");
    } 
  }
}

void main() {
  new ParserTest().run();
  new InterpreterTest().run();
}
