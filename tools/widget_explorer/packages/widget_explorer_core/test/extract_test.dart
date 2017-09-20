// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:widget_explorer_core/widget_specs.dart';

import 'util.dart';

Future<Null> main() async {
  String mockPackagePath = path.join(getTestDataPath(), 'mock_package');
  String fuchsiaRoot = path.join(
    mockPackagePath,
    '..',
    '..',
    '..',
    '..',
    '..',
    '..',
    '..',
  );

  // Run 'flutter packages get'
  await Process.run(
    'flutter',
    <String>['packages', 'get'],
    workingDirectory: mockPackagePath,
  );

  List<WidgetSpecs> widgetSpecs = extractWidgetSpecs(
    mockPackagePath,
    fuchsiaRoot: fuchsiaRoot,
  );

  Map<String, WidgetSpecs> widgetMap =
      new Map<String, WidgetSpecs>.fromIterable(
    widgetSpecs,
    key: (WidgetSpecs ws) => ws.name,
    value: (WidgetSpecs ws) => ws,
  );

  test('extractWidgetSpecs() should extract only public flutter widgets.', () {
    expect(
        widgetMap.keys,
        unorderedEquals(<String>[
          'Widget01',
          'Widget03',
          'NoCommentWidget',
          'ConfigKeyWidget',
          'GeneratorWidget',
          'SizeParamWidget',
        ]));
  });

  test('extractWidgetSpecs() should correctly extract dartdoc comments.', () {
    expect(
      widgetMap['Widget01'].doc,
      equals('This is a public [StatefulWidget].'),
    );
    expect(
      widgetMap['Widget03'].doc,
      equals('This is a public [StatelessWidget].'),
    );
    expect(widgetMap['NoCommentWidget'].doc, isNull);
  });

  test('extractWidgetSpecs() should correctly extract the package name.', () {
    widgetMap.keys.forEach((String key) {
      expect(widgetMap[key].packageName, equals('mock_package'));
    });
  });

  test('extractWidgetSpecs() should correctly extract the path.', () {
    widgetMap.keys.forEach((String key) {
      expect(widgetMap[key].path, equals('exported.dart'));
    });
  });

  test(
      'extractWidgetSpecs() should correctly extract '
      'relative path from fuchsia root.', () {
    Map<String, String> expected = <String, String>{
      'Widget01': 'sample_widgets.dart',
      'Widget03': 'sample_widgets.dart',
      'NoCommentWidget': 'sample_widgets.dart',
      'ConfigKeyWidget': 'config_key_widget.dart',
      'GeneratorWidget': 'generator_widget.dart',
      'SizeParamWidget': 'size_param_widget.dart',
    };

    widgetMap.keys.forEach((String key) {
      expect(
          widgetMap[key].pathFromFuchsiaRoot,
          equals(
              'topaz/tools/testdata/widget_specs/extract_test/mock_package/lib/src/${expected[key]}'));
    });
  });

  test('The extracted ClassElement should have annotation information.', () {
    WidgetSpecs specs = widgetMap['Widget01'];

    expect(specs.constructor, isNotNull);
    Map<String, dynamic> expectedExampleValues = <String, dynamic>{
      'intParam': 42,
      'boolParam': true,
      'doubleParam': 10.0,
      'stringParam': 'example string value!',
    };

    specs.constructor.parameters.forEach((ParameterElement param) {
      // Find the @ExampleValue annotation.
      ElementAnnotation exampleValueAnnotation =
          specs.getExampleValueAnnotation(param);

      if (exampleValueAnnotation != null) {
        expect(param.name, isIn(expectedExampleValues.keys));
        expect(specs.getExampleValue(param),
            equals(expectedExampleValues[param.name]));
      } else {
        expect(param.name, isNot(isIn(expectedExampleValues.keys)));
      }
    });
  });

  test('The example size should be correctly extracted.', () {
    WidgetSpecs widget01 = widgetMap['Widget01'];
    const double delta = 1e-10;

    expect(widget01.exampleWidth, closeTo(200.0, delta));
    expect(widget01.exampleHeight, closeTo(300.0, delta));

    widgetMap.values
        .where((WidgetSpecs ws) => ws != widget01)
        .forEach((WidgetSpecs ws) {
      expect(ws.exampleWidth, isNull);
      expect(ws.exampleHeight, isNull);
    });
  });

  test('The hasSizeParam value should be correctly extracted.', () {
    WidgetSpecs sizeParamWidget = widgetMap['SizeParamWidget'];
    expect(sizeParamWidget.hasSizeParam, isTrue);

    widgetMap.values
        .where((WidgetSpecs ws) => ws != sizeParamWidget)
        .forEach((WidgetSpecs ws) => expect(ws.hasSizeParam, isFalse));
  });
}
