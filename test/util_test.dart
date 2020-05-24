/// Test the utility functions.
library util_test;

import 'package:game_utils/game_utils.dart';
import 'package:test/test.dart';

void main() {
  group('englishList tests', () {
    test('Empty list', () {
      expect(englishList(<String>[]), equals('nothing'));
    });

    test('Two items', () {
      expect(englishList(<String>['apples', 'pears']), equals('apples, and pears'));
    });

    test('Multiple items', () {
      final List<String> fruit = <String>['apples', 'pears', 'bananas'];
      expect(englishList(fruit), equals('apples, pears, and bananas'));
    });
  });
}
