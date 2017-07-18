// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'model.dart';

const Duration _fadeAnimationDuration = const Duration(seconds: 1);
const double _fadeToScaleRatio = 0.2;
const double _fadeMinScale = 0.6;
const Curve _fadeCurve = Curves.fastOutSlowIn;

/// Frame for child views
class SurfaceWidget extends StatelessWidget {
  /// If true then ChildView hit tests will go through
  final bool interactable;

  /// How much to fade this surface [0.0, 1.0]
  final double fade;

  /// Constructor
  SurfaceWidget({Key key, this.interactable: true, this.fade: 0.0})
      : super(key: key) {
    assert(0.0 <= fade && fade <= 1.0);
  }

  @override
  Widget build(BuildContext context) => new ScopedModelDescendant<Surface>(
        child: new Container(),
        builder: (BuildContext context, Widget blank, Surface surface) =>
            new LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                Widget childView = new Stack(children: <Widget>[
                  new PhysicalModel(
                    elevation: 10.0,
                    color: const Color(0x00000000),
                    child: new AnimatedOpacity(
                      key: new ObjectKey(surface),
                      duration: _fadeAnimationDuration,
                      opacity: 1.0 - fade,
                      curve: _fadeCurve,
                      child: surface.connection == null
                          ? blank
                          : new ChildView(
                              connection: surface.connection,
                              hitTestable: interactable,
                            ),
                    ),
                  ),
                ]);
                return new AnimatedContainer(
                  key: new ObjectKey(surface),
                  duration: _fadeAnimationDuration,
                  curve: _fadeCurve,
                  transform: _scale(constraints.biggest.center(Offset.zero)),
                  margin: const EdgeInsets.all(2.0),
                  padding: const EdgeInsets.all(20.0),
                  child: childView,
                );
              },
            ),
      );

  Matrix4 _scale(Offset center) {
    double scale = math.max(_fadeMinScale, 1.0 - _fadeToScaleRatio * fade);
    Matrix4 matrix = new Matrix4.identity();
    matrix.translate(center.dx, center.dy);
    matrix.scale(scale, scale);
    matrix.translate(-center.dx, -center.dy);
    return matrix;
  }
}
