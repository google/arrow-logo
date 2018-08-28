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
import 'dart:html' as html;
import 'dart:math' as math;

import 'nodes.dart';
import 'turtle.dart';

/**
 * Receives turtle commands and executes them.
 */
class TurtleWorkerImpl extends TurtleWorker {
  Turtle turtle;

  static num getNum(String sizePx) {
    final size = sizePx.substring(0, sizePx.length - 2);
    return int.parse(size);
  }

  init(userCanvas, turtleCanvas) {
    var userCtx = userCanvas.getContext("2d");
    var turtleCtx = turtleCanvas.getContext("2d");

    html.CssStyleDeclaration style = userCanvas.getComputedStyle();
    final width = getNum(style.width);
    final height = getNum(style.height);
    turtle = new Turtle(turtleCtx, userCtx, width, height);
    turtle.draw();
  }

  // TODO: consider turning into a logo object right here?
  TurtleState get state => turtle.state;

  void receive(Primitive prim, List<dynamic> args) {
    switch (prim) {
      case Primitive.BACK:
        turtle.back(args[0]);
        break;

      case Primitive.CLEAN:
        turtle.clean();
        break;

      case Primitive.CLEARSCREEN:
        turtle.clean();
        turtle.home();
        break;

      case Primitive.DRAWTEXT:
        turtle.drawText(args[0]);
        break;

      case Primitive.FORWARD:
        turtle.forward(args[0]);
        break;

      case Primitive.LEFT:
        turtle.left(args[0]);
        break;

      case Primitive.RIGHT:
        turtle.right(args[0]);
        break;

      case Primitive.HIDETURTLE:
        turtle.hideTurtle();
        break;

      case Primitive.HOME:
        turtle.home();
        break;

      case Primitive.PENDOWN:
        turtle.penDown();
        break;

      case Primitive.PENUP:
        turtle.penUp();
        break;

      case Primitive.SHOWTURTLE:
        turtle.showTurtle();
        break;

      case Primitive.RIGHT:
        turtle.right(args[0]);
        break;

      case Primitive.SETPENCOLOR:
        turtle.setPenColor(args[0]);
        break;

      case Primitive.SETFONT:
        turtle.font = args[0];
        break;

      case Primitive.SETTEXTALIGN:
        turtle.textAlign = args[0];
        break;

      case Primitive.SETTEXTBASELINE:
        turtle.textBaseline = args[0];
        break;
    }
    turtle.draw();
  }
}

/**
 * Keeps state of the turtle and updates canvas when drawing.
 */
class Turtle {
  static final ORANGE = "orange";
  static final GREEN = "green";
  static final BLACK = "black";
  static final TAU = math.pi * 2;

  static final List<String> colorTable = [
    "black",
    "red",
    "green",
    "yellow",
    "blue",
    "fuchsia",
    "aqua",
    "white",
    "darkgray",
    "lightgray",
    "darkred",
    "forestgreen",
    "darkblue",
    "gold",
    "lightpink",
    "darkviolet",
    "darkgoldenrod"
  ];
  static final SHOW = 0;
  static final HIDE = 1;
  static final PENUP = 0;
  static final PENDOWN = 1;

  final html.CanvasRenderingContext2D turtleCtx;
  final html.CanvasRenderingContext2D userCtx;
  final num xmax;
  final num ymax;
  num xhome;
  num yhome;

  num x;
  num y;
  num heading;
  num delta;

  int showHide;
  int penUpDown;

  String penColor;
  String backgroundColor;
  String font = "12px sans-serif";
  // one of {start, end, left, right, center}
  String textAlign = "left";
  // one of {top, hanging, middle, alphabetic, ideographic, bottom}
  String textBaseline = "bottom";

  Turtle(this.turtleCtx, this.userCtx, this.xmax, this.ymax) {
    xhome = xmax / 2;
    yhome = ymax / 2;
    delta = 0;
    showHide = SHOW;
    penUpDown = PENDOWN;
    penColor = colorTable[0];
    backgroundColor = "white";
    blankCtx(userCtx);
    home();
  }

  TurtleState get state =>
      new TurtleState(x.toDouble(), y.toDouble(), heading.toDouble());

  double getHeadingRad() {
    return TAU * (heading / 360.0);
  }

  void clean() {
    blankCtx(userCtx);
  }

  void cleanCtx(html.CanvasRenderingContext2D ctx) {
    ctx.clearRect(0, 0, xmax, ymax);
  }

  void blankCtx(html.CanvasRenderingContext2D ctx) {
    ctx.fillStyle = backgroundColor;
    ctx.fillRect(0, 0, xmax, ymax);
  }

  void drawText(String text) {
    userCtx.font = font;
    userCtx.textAlign = textAlign;
    userCtx.textBaseline = textBaseline;
    userCtx.fillStyle = penColor;
    userCtx.fillText(text, x, y);
  }

  void home() {
    x = xhome;
    y = yhome;
    heading = -90;
  }

  void back(num delta_) {
    delta -= delta_;
  }

  void forward(num delta_) {
    delta = delta_;
  }

  void left(num angle) {
    heading -= angle;
  }

  void right(num angle) {
    heading += angle;
  }

  bool setPenColor(int colorCode) {
    if (colorCode < 0 && colorCode >= colorTable.length) {
      return false;
    }
    penColor = colorTable[colorCode];
    return true;
  }

  void drawFillCircle(ctx, num x_, num y_, num radius, color) {
    ctx.beginPath();
    ctx.lineWidth = 2;
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.arc(x_, y_, radius, 0, TAU, false);
    ctx.fill();
  }

  void drawTurtle() {
    final baseHeading = getHeadingRad();
    const BODY_RADIUS = 12;

    drawFillCircle(turtleCtx, x, y, BODY_RADIUS, ORANGE);
    final headX = x + BODY_RADIUS * math.cos(baseHeading);
    final headY = y + BODY_RADIUS * math.sin(baseHeading);
    drawFillCircle(turtleCtx, headX, headY, 2, GREEN);

    num footX = x + BODY_RADIUS * math.cos(baseHeading + TAU / 8);
    num footY = y + BODY_RADIUS * math.sin(baseHeading + TAU / 8);
    drawFillCircle(turtleCtx, footX, footY, 1, BLACK);

    footX = x + BODY_RADIUS * math.cos(baseHeading - TAU / 8);
    footY = y + BODY_RADIUS * math.sin(baseHeading - TAU / 8);
    drawFillCircle(turtleCtx, footX, footY, 1, BLACK);

    footX = x + BODY_RADIUS * math.cos(baseHeading + TAU * 3 / 8);
    footY = y + BODY_RADIUS * math.sin(baseHeading + TAU * 3 / 8);
    drawFillCircle(turtleCtx, footX, footY, 1, BLACK);

    footX = x + BODY_RADIUS * math.cos(baseHeading - TAU * 3 / 8);
    footY = y + BODY_RADIUS * math.sin(baseHeading - TAU * 3 / 8);
    drawFillCircle(turtleCtx, footX, footY, 1, BLACK);
  }

  void draw() {
    final baseHeading = getHeadingRad();
    final deltaX = math.cos(baseHeading);
    final deltaY = math.sin(baseHeading);
    final newX = x + delta * deltaX;
    final newY = y + delta * deltaY;
    cleanCtx(turtleCtx);
    if (delta != 0 && penUpDown == PENDOWN) {
      userCtx.beginPath();
      userCtx.lineWidth = 2;
      userCtx.fillStyle = penColor;
      userCtx.strokeStyle = penColor;
      userCtx.moveTo(x, y);
      userCtx.lineTo(newX, newY);
      userCtx.stroke();
      userCtx.closePath();
    }
    x = newX;
    y = newY;
    if (showHide == SHOW) {
      drawTurtle();
    }
    delta = 0;
  }

  void hideTurtle() {
    showHide = HIDE;
  }

  void showTurtle() {
    showHide = SHOW;
  }

  void penUp() {
    penUpDown = PENUP;
  }

  void penDown() {
    penUpDown = PENDOWN;
  }
}
