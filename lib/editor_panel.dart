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

library editor_panel;

import 'package:angular2/angular2.dart';

import 'console.dart';

@Component(selector: 'editor-panel')
@View(
    template: '''
<style>
div.panel {
  position: absolute;
  left: 610px;
  width: 300px;
  height: 540px;
  right: 0px;
}

textarea#history, textarea#shell, div#editorBackground {
  font-family: monospace;
  width: 300px;
  background: rgb(230,230,230);
}

textarea#history {
  height: 502px;
}

textarea#shell {
  height: 20px;
}

div#editor, div#editorBackground {
  position: absolute;
  left: 0;
  top: 0;
  height: 540px;
  width: 300px;
}

input#load {
  display: none;  /* TODO */
  right: 5em;
  bottom: 1em;
}

input#download {
  position: absolute;
  right: 5em;
  bottom: 1em;
}

input#commit {
  position: absolute;
  right: 1em;
  bottom: 1em;
}
</style>
<div class="panel">
  <textarea id="shell"></textarea>
  <textarea id="history"></textarea>
  <div class="editor">
    <div id="editorBackground" class="invisible"></div>
    <div id="editor" class="invisible"></div>
    <input id="load" type="file" value="" class="invisible">
    <input id="download" type="button" value="save" class="invisible">
    <input id="commit" type="button" value="ok" class="invisible">
  </div>
</div>
''')
class EditorPanel implements OnInit {
  ElementRef elementRef;
  Console console;
  EditorPanel(this.console, this.elementRef);

  @override
  ngOnInit() {
    console.init(elementRef.nativeElement);
  }
}
