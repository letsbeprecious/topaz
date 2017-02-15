// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xi_widgets/widgets.dart';

import 'src/xi_flutter_client.dart';

import 'package:flutter/rendering.dart' show
  debugPaintSizeEnabled,
  debugPaintBaselinesEnabled,
  debugPaintLayerBordersEnabled,
  debugPaintPointersEnabled,
  debugRepaintRainbowEnabled;

Future<Null> main() async {
  //debugRepaintRainbowEnabled = true;
  XiFlutterClient xi = new XiFlutterClient();
  runApp(new XiApp(xi: xi));
}
