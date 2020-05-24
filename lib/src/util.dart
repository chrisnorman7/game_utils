/// Provides utility methods.
library util;

import 'dart:math';

/// Random number generator.
final Random random = Random();

/// Convert a list of items to a properly formatted english list.
String englishList(List<String> items, {String andString = ', and ', String sepString = ', ', String emptyString = 'nothing'}) {
  if (items.isEmpty) {
    return emptyString;
  }
  if (items.length == 1) {
    return items[0];
  }
  String string = '';
  final int lastIndex = items.length - 1;
  final int penultimateIndex = lastIndex - 1;
  for (int i = 0; i < items.length; i++) {
    final String item = items[i];
    string += item;
    if (i == penultimateIndex) {
      string += andString;
    } else if (i != lastIndex) {
      string += sepString;
    }
  }
  return string;
}

/// Generate a random number between start and end inclusive.
int randInt(int end, {int start = 0}) {
  return random.nextInt(end) + start;
}

/// Return a random element from a list.
///
/// This function doesn't check for an empty list.
T randomElement<T>(List<T> items) {
  return items[randInt(items.length)];
}

/// A shortcut for getting a milliseconds timestamp.
int timestamp() {
  return DateTime.now().millisecondsSinceEpoch;
}
