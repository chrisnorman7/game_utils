import 'dart:html';
import 'dart:web_audio';

import 'package:game_utils/game_utils.dart';

/// The webaudio context.
AudioContext ctx;

/// The sound system.
SoundPool sounds;

/// The message area.
final Element message = querySelector('#message');

void main() {
  /// The output type for volume changes.
  //
  // Since we're adjusting sounds, rather than ambiences or music.
  const OutputTypes outputType = OutputTypes.sound;
  // Unhide the main div.
  querySelector('#output').hidden = false;
  // Get the play button.
  final ButtonElement b = querySelector('#play') as ButtonElement;
  // Get the volume up button.
  final ButtonElement vu = querySelector('#volumeUp') as ButtonElement;
  // Get the volume down button.
  final ButtonElement vd = querySelector('#volumeDown') as ButtonElement;
  // Disable both volume buttons until the sound system has been initialised.
  vu.disabled = true;
  vd.disabled = true;
  b.onClick.listen((MouseEvent e) {
    if (ctx == null) {
      ctx = AudioContext();
      sounds = SoundPool(ctx, showMessage: (String m) => message.innerText = m);
      vu.disabled = false;
      vd.disabled = false;
      vu.onClick.listen((MouseEvent e) => sounds.volumeUp(outputType));
      vd.onClick.listen((MouseEvent e) => sounds.volumeDown(outputType));
    }
    sounds.playSound('sound.wav');
  });
}