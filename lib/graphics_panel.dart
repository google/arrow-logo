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

import "turtle.dart";

@Component(
    selector: 'graphics-panel',
    template: '''
<div class="graphics_panel">
  <canvas id="user" width="600" height="540"></canvas>
  <canvas id="turtle" width="600" height="540"></canvas>
</div>
''')
class GraphicsPanel implements OnInit {
  Element element;
  TurtleWorker turtleWorker;

  GraphicsPanel(this.turtleWorker, this.element);

  @override
  ngOnInit() {
    final userCanvas = element.querySelector("#user");
    final turtleCanvas = element.querySelector("#turtle");

    turtleWorker.init(userCanvas, turtleCanvas);
  }
}
