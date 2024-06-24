// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CommonTestCases {
  WidgetTester tester;
  CommonTestCases(this.tester);

  Future<void> isSpecificPage<T>() async {
    await tester.pumpAndSettle();
    hasType<T>();
  }

  Future<void> tapItemByKey(String key) async {
    final widget = find.byKey(ValueKey(key));
    await tester.tap(widget);
    await tester.pumpAndSettle();
  }

  void hasText(String text, {bool hasWidget = true}) {
    final textWidget = find.text(text);
    expect(textWidget, hasWidget ? findsOneWidget : findsNothing);
  }

  void hasType<T>() {
    final typeWidget = find.byType(T);
    expect(typeWidget, findsOneWidget);
  }

  void hasKey(String key) {
    final typeWidget = find.byKey(ValueKey(key));
    expect(typeWidget, findsOneWidget);
  }

  Future<void> goBack() async {
    tester.printToConsole('Routing back to previous screen');
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
  }

  void defaultSleepTime() => sleep(Duration(seconds: 2));
}
