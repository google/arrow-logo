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

typedef void ConsoleInterpreterFn(String);

// Provides textual output functionality for both the app and user code.
abstract class ArrowConsole {
  ArrowConsole() {}

  init(dynamic element);

  set interpreter(ConsoleInterpreterFn doInterpret);

  /// Processes a user command (e.g. "print").
  void processAction(List action);

  /// Prints a confirmation that the user defined [defnName].
  void processDefined(String defnName);

  /// Logs an exception.
  void processException(String exceptionMessage);

  /// Logs a trace string.
  void processTrace(String traceString);
}
