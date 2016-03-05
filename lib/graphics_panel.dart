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

library graphics_panel;

import 'package:angular2/angular2.dart';

import "turtle.dart";

@Component(
  selector: 'graphics-panel'
)
@View(
  template: '''
<style>
div.graphics_panel {
  position: absolute;
  width: 600px;
  height: 540px;
}

canvas#user, canvas#turtle {
  position: absolute;
  left: 0;
  top: 0;
  width: 600px;
  height: 540px;
}

canvas#user {
  z-index: 0;
}

canvas#turtle {
  z-index: 1;
}
</style>
<div class="graphics_panel">
  <canvas id="user"  width="600" height="540"></canvas>
  <canvas id="turtle" width="600" height="540"></canvas>
</div>
'''
)
class GraphicsPanel {
  TurtleWorker turtleWorker;

  GraphicsPanel(this.turtleWorker, ElementRef elementRef) {
    final userCanvas = elementRef.nativeElement.querySelector("#user");
    final turtleCanvas = elementRef.nativeElement.querySelector("#turtle");

    turtleWorker.init(userCanvas, turtleCanvas);
  }
}