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

// Runs all unit tests. Use this command line:
// dart --enable-checked-mode --package-root=`pwd`/packages/ tests/tests.dart
library arrowlogo;

import 'interpreter_test.dart';
import 'node_test.dart';
import 'parser_test.dart';

void main() {
  new NodeTest().run();
  new ParserTest().run();
  new InterpreterTest().run();
}