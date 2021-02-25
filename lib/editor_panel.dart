// Copyright 2015 Google Inc. All Rights Reserved.
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

import 'dart:html';

import 'package:angular/angular.dart';

import 'console.dart';

@Component(
    selector: 'editor-panel',
    template: '''
<div class="panel">
  <textarea id="shell"></textarea>
  <textarea id="history"></textarea>
  <div class="editorBox">
    <div id="editor"
         class="invisible" contenteditable="true" spellcheck="false"></div>
    <input id="load" type="file" value="" class="invisible">
    <input id="download" type="button" value="download" class="invisible">
    <input id="run" type="button" value="run" class="invisible">
    <input id="close" type="button" value="close" class="invisible">
  </div>
</div>
''')
class EditorPanel implements OnInit {
  Element element;
  ArrowConsole console;
  EditorPanel(this.console, this.element);

  @override
  ngOnInit() {
    console.init(element);
  }
}
