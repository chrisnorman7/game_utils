/// Provides the Keyboard class.
library keyboard;

import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';

/// A key with modifiers.
@immutable
class KeyState {
  /// Create a instance.
  ///
  /// ```
  /// final KeyState printKey = KeyState('p', control: true);
  /// final KeyState escapeKey = KeyState('escape');
  /// ```
  const KeyState(
    this.key,
    {
      this.shift = false,
      this.control = false,
      this.alt = false
    }
  );

  /// A non-modifier key.
  final String key;

  /// Modifier keys.
  final bool shift, control, alt;

  @override
  int get hashCode {
    return toString().hashCode;
  }

  @override
  bool operator == (dynamic other) {
    if (other is KeyState) {
      return other.hashCode == hashCode;
    }
    return false;
  }

  /// Returns a human-readable string, like "ctrl+p", or "f12".
  @override
  String toString() {
    final List<String> keys = <String>[];
    if (control) {
      keys.add('ctrl');
    }
    if (alt) {
      keys.add('alt');
    }
    if (shift) {
      keys.add('shift');
    }
    const Map<String, String> hotkeyConvertions = <String, String>{
      ' ': 'Space',
    };
    String keyString = key;
    if (hotkeyConvertions.containsKey(keyString)) {
      keyString = hotkeyConvertions[keyString];
    }
    keys.add(keyString);
    return keys.join('+');
  }
}

/// A class for triggering [Hotkey] instances.
class Keyboard {
  /// Create the keyboard, adding a callback for when hotkeys throw an error.
  ///
  ///
  /// final Keyboard kb = Keyboard((dynamic e) => print(e));
  /// ```
  ///
  /// If you want to handle unhandled keys yourself, provide a [unhandledKey] argument.
  Keyboard(this.onError, {this.unhandledKey});

  /// The function which is called when [Hotkey] instances throw an error.
  void Function(dynamic, StackTrace) onError;

  /// The function to call when a key is pressed that is not handled by any of the hotkeys added with [addHotkey].
  void Function(KeyState) unhandledKey;

  /// The keys which are currently held down.
  List<KeyState> heldKeys = <KeyState>[];

  /// The hotkeys registered to this instance.
  List<Hotkey> hotkeys = <Hotkey>[];

  /// The one-time [Hotkey] instances which have already been handled. This list will be cleared as the keys for those hotkeys are released.
  List<Hotkey> handledHotkeys = <Hotkey>[];

  /// Returns [true] if [key] is held down.
  ///
  /// ```
  /// if (keyboard.keyHeld(' ')) {
  ///   // Fire weapon.
  /// }
  /// ```
  bool keyHeld(String key) {
    return heldKeys.where((KeyState state) => state.key == key).isNotEmpty;
  }

  /// Register a key as pressed.
  ///
  /// Returns the key that was pressed, converted to a [KeyState] instance.
  ///
  /// ```
  /// element.onKeyDown.listen((KeyboardEvent e) => keyboard.press(
  ///   e.key, control: e.ctrlKey, shift: e.shiftKey, alt: e.altKey
  /// ));
  /// ```
  KeyState press(
    String key, {
      bool shift = false,
      bool control = false,
      bool alt = false
    }
  ) {
    final KeyState state = KeyState(key, shift: shift, control: control, alt: alt);
    if (!keyHeld(state.key)) {
      heldKeys.add(state);
      bool handled = false;
      for (final Hotkey hk in hotkeys) {
        if (hk.state == state && (hk.runWhen == null || hk.runWhen())) {
          handled = true;
          if (hk.interval == null) {
            hk.run();
          } else {
            hk.startTimer();
          }
        }
      }
      if (!handled && unhandledKey != null) {
        unhandledKey(state);
      }
    }
    return state;
  }

  /// Release a key.
  ///
  /// ```
  /// element.onKeyUp.listen((KeyboardEvent e) => keyboard.release(e.key);
  /// ```
  void release(String key) {
    heldKeys.removeWhere((KeyState state) => state.key == key);
    for (final Hotkey hk in hotkeys) {
      if (hk.state.key == key && hk.timer != null) {
        hk.stopTimer();
      }
    }
  }

  /// Release all held keys.
  void releaseAll() {
    for (final KeyState state in heldKeys) {
      release(state.key);
    }
  }

  /// Add a [Hotkey] instance to this keyboard.
  ///
  /// ```
  /// final Hotkey hk = Hotkey(
  ///   't', () => print('Test.'),
  ///   titleString: 'Test hotkeys'
  /// );
  /// keyboard.addHotkey(hk);
  /// ```
  void addHotkey(Hotkey hk) {
    hotkeys.add(hk);
    querySelector('#hotkeys').append(ParagraphElement()
        ..innerText = '${hk.state}: ${hk.getTitle()}');
  }

  /// Remove a hotkey.
  ///
  /// ```
  /// keyboard.remove(noLongerNeededHotkey);
  /// ```
  void removeHotkey(Hotkey hk) {
    hotkeys.remove(hk);
  }

  /// Add multiple hotkeys.
  /// ```
  /// final List<Hotkey> hotkeys = <Hotkey>[...];
  /// keyboard.addHotkeys(hotkeys);
  /// ```
  void addHotkeys(List<Hotkey> hotkeys) {
    hotkeys.forEach(addHotkey);
  }
}

/// A hotkey.
///
/// Used by [Keyboard.addHotkey].
class Hotkey {
  /// Create a hotkey.
  ///
  /// ```
  /// final Hotkey hk = Hotkey(
  ///   keyboard, 't', () => print('Test.'),
  ///   titleString: 'Test hotkeys'
  /// );
  /// ```
  ///
  /// The function [func] will fire when the hotkey is pressed. It will be called via [run], so that errors are handled appropriately.
  ///
  /// If [interval] is not null, then [func] will be called every [interval] milliseconds.
  ///
  /// If [runWhen] is not null, only run [func] when [runWhen] returns true.
  Hotkey(
    this.keyboard, String key, this.func, {
      this.titleString, this.titleFunc, this.interval, this.runWhen,
      bool shift = false, bool control = false, bool alt = false
    }
  ) {
    state = KeyState(key, shift: shift, alt: alt, control: control);
  }

  /// The keyboard this hotkey is bound to.
  final Keyboard keyboard;

  /// The key which must be pressed in order that this hotkey is fired.
  KeyState state;

  /// The title of this hotkey.
  final String titleString;

  /// A function which when called should return the title of this hotkey.
  final String Function() titleFunc;

  /// The hotkey callback, to be called with [state] as its only argument.
  final void Function() func;

  /// The interval between firing [func].
  ///
  /// If this value is null, then this key will only fire once when the key is pressed.
  int interval;

  /// A function which determines whether [func] should be called.
  final bool Function() runWhen;

  /// The timer that will call [func] via [run].
  Timer timer;

  /// The time this hotkey was last run.
  int lastRun;

  /// Start the timer to call [run] every [interval] milliseconds.
  void startTimer() {
    if (timer != null) {
      stopTimer();
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (lastRun == null || (now - lastRun) > interval) {
      lastRun = now;
      run();
    }
    timer = Timer.periodic(Duration(milliseconds: interval), (Timer t) => run());
  }

  /// Stop [timer].
  void stopTimer() {
    timer.cancel();
    timer = null;
  }

  /// Call [func], and handle errors.
  void run() {
    if (!keyboard.heldKeys.contains(state)) {
      return;
    }
    try {
      if (runWhen == null || runWhen()) {
        func();
      }
    }
    catch (e, s) {
      keyboard.onError(e, s);
    }
  }

  /// Returns a [String] representing the title of this hotkey. If [titleString] was not provided, then [titleFunc]() will be returned instead.
  String getTitle() {
    if (titleString == null) {
      if (titleFunc != null) {
        return titleFunc();
      }
    }
    return titleString;
  }
}
