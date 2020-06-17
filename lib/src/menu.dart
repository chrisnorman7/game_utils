/// Provides the [Book] class, which can be used for making menus.
library book;

import 'keyboard.dart';

import 'sound_pool.dart';
import 'util.dart';

/// The type for all titleFunc arguments.
typedef TitleFunctionType = String Function();

/// The type for all [Line] functions.
typedef BookFunctionType = void Function();

/// The options for a [Book] instance.
///
/// This allows you to share configuration over multiple books.
class BookOptions {
  BookOptions(
    this.soundPool, this.message, {
      this.searchSuccessSoundUrl = 'sounds/menus/searchsuccess.wav',
      this.searchFailSoundUrl = 'sounds/menus/searchfail.wav',
      this.moveSoundUrl = 'sounds/menus/move.wav',
      this.activateSoundUrl = 'sounds/menus/activate.wav',
      this.noCancelSoundUrl = 'sounds/menus/nocancel.wav'
    }
  ) {
    searchFailSound = soundPool.getSound(searchFailSoundUrl);
    searchSuccessSound = soundPool.getSound(searchSuccessSoundUrl);
    moveSound = soundPool.getSound(moveSoundUrl);
    noCancelSound = soundPool.getSound(noCancelSoundUrl);
    activateSound = soundPool.getSound(activateSoundUrl);
  }

  /// An interface for playing sounds.
  SoundPool soundPool;

  /// The function to use for showing text.
  final void Function(String) message;

  /// The URL sound to play when a search matches a result.
  String searchSuccessSoundUrl;

  /// The sound associated with [searchSuccessSoundUrl];
  Sound searchSuccessSound;

  /// The sound to play when a search matches nothing.
  String searchFailSoundUrl;

  /// The sound associated with [searchFailSoundUrl].
  Sound searchFailSound;

  /// The url of the sound to play when moving through the menu.
  String moveSoundUrl;

  /// The sound associated with [moveSoundUrl].
  Sound moveSound;

  /// The url of the sound to play when using [Book.cancel].
  String noCancelSoundUrl;

  /// The sound associated with [noCancelSoundUrl];
  Sound noCancelSound;

  /// The url of the sound to play when using [Book.activate].
  String activateSoundUrl;

  // The sound associated with [activateSoundUrl].
  Sound activateSound;

  /// The timeout (in milliseconds) for searches.
  int searchTimeout = 500;
}

/// A book, which acts like a menu.
///
/// Books contain [Page] instances, which can be added with [Book.push].
///
///You can traverse through the menu with [Book.moveUp], [Book.moveDown].
///
/// You can return to the previous [Page] with [Book.cancel], which uses [Book.pop] to "pop" the most recently added [Page].
/// You can activate items with [Book.activate].
class Book{
  /// Give it the ability to make sounds, and the ability to send messages.
  Book(this.options);

  /// The options for this book.
  final BookOptions options;

  /// The most recent search string.
  String searchString;

  /// The last time a search was performed.
  int lastSearchTime;

  /// The pages contained by this book.
  ///
  /// Using [push] to add another page will increase the stack depth, while using [pop] will decrease it.
  List<Page> pages = <Page>[];

  /// Push a [Page] instance.
  ///
  /// This creates a new menu, as menu items are really [Line] instances contained by a [Page] instance.
  void push(Page page) {
    lastSearchTime = 0;
    pages.add(page);
    showFocus();
  }

  /// Pop a [Page] instance from the end of the stack.
  ///
  /// This returns focus to the previous menu.
  Page pop() {
    final Page oldPage = pages.removeLast(); // Remove the last page from the list.
    if (pages.isNotEmpty) {
      final Page page = pages.removeLast(); // Pop the next one too, so we can push it again.
      push(page);
    }
    return oldPage;
  }

  /// Get the current page.
  ///
  /// If there are no pages, then null is returned.
  Page getPage() {
    if (pages.isNotEmpty) {
      return pages[pages.length - 1];
    }
    return null;
  }

  /// Get the current focus as an integer. If no page is focussed ([getPage] returns null), then null is returned.
  ///
  /// ```
  /// book.pages[book.getFocus()] == book.getPage();
  /// ```
  int getFocus() {
    final Page page = getPage();
    if (page == null) {
      return null;
    }
    return page.focus;
  }

  /// Using `[options].message`, print the title of the currently active [Page].
  ///
  /// If no page is currently focussed ([getPage] returns null), then an error is thrown.
  void showFocus() {
    final Page page = getPage();
    if (page == null) {
      throw 'First push a page.';
    } else if (page.focus == -1) {
      options.message(page.getTitle());
    } else {
      final Line line = page.getLine();
      String url;
      if (line.soundUrl != null) {
        url = line.soundUrl();
      } else if (page.playDefaultSounds) {
        url = options.moveSoundUrl;
      }
      options.moveSound.stop();
      if (url != null) {
        options.moveSound = options.soundPool.playSound(url, output: options.soundPool.output);
      }
      options.message(line.getTitle());
    }
  }

  /// Move upwards through the current [Page]'s list of [Line] instances.
  ///
  /// Should probably be triggered by arrow keys or some such.
  void moveUp() {
    final Page page = getPage();
    if (page == null) {
      return; // There"s probably no pages.
    }
    final int focus = getFocus();
    if (focus == -1) {
      return; // Do nothing.
    }
    page.focus --;
    showFocus();
  }

  /// Move downwards through the current [Page]'s list of [Line] instances.
  ///
  /// Should probably be triggered by arrow keys or some such.
  void moveDown() {
    final Page page = getPage();
    if (page == null) {
      return; // There"s no pages.
    }
    final int focus = getFocus();
    if (focus == (page.lines.length - 1)) {
      return; // Can't move down any further.
    }
    page.focus++;
    showFocus();
  }

  /// Call [Line.func] on the currently focussed [Line] instance of the currently active [Page] instance.
  ///
  /// Should probably be triggered by the enter key or space.
  void activate() {
    final Page page = getPage();
    if (page == null) {
      return; // Can"t do anything with no page.
    }
    final Line line = page.getLine();
    if (line == null) {
      return; // They are probably looking at the title.
    }
    if (options.activateSoundUrl != null) {
      options.activateSound = options.soundPool.playSound(options.activateSoundUrl, output: options.soundPool.output);
    }
    line.func();
  }

  /// Cancel and remove the currently active [Page] instance, and pop it from the stack.
  ///
  /// Should probably be triggered by left arrow, or some sort of back button.
  void cancel() {
    final Page page = getPage();
    if (page == null) {
      return;
    } else if (!page.dismissible) {
      options.noCancelSound.stop();
      if (options.noCancelSoundUrl != null) {
        options.noCancelSound = options.soundPool.playSound(options.noCancelSoundUrl, output: options.soundPool.output);
      }
    } else {
      pop();
      if (page.onCancel != null) {
        page.onCancel();
      }
    }
  }

  /// Handle a search string.
  ///
  /// This method adds [term] to [searchString], and performs the search.
  ///
  /// If the last search was performed too long ago (according to [lastSearchTime], then [searchString] will be reset to an empty string first.
  ///
  /// Should probably be triggered by letter keys with no modifiers, or some kind of alternate keyboard.
  void handleSearch(String term) {
    final Page page = getPage();
    if (page == null) {
      return; // Don't search when there is no page.
    }
    final int now = timestamp();
    if ((now - lastSearchTime) >= options.searchTimeout) {
      searchString = '';
    }
    lastSearchTime = now;
    searchString += term.toLowerCase();
    final int index = page.lines.indexWhere(
      (Line entry) => entry.getTitle().toLowerCase().startsWith(searchString)
    );
    if (index == -1) {
      options.searchSuccessSound.stop();
      if (options.searchFailSoundUrl != null) {
        options.searchFailSound = options.soundPool.playSound(options.searchFailSoundUrl, output: options.soundPool.output);
      }
    } else {
      options.searchFailSound.stop();
      if (options.searchSuccessSoundUrl != null) {
        options.searchSuccessSound = options.soundPool.getSound(options.searchSuccessSoundUrl);
      }
      page.focus = index;
      showFocus();
    }
  }
}

/// A menu item.
///
/// ```
/// final Line line = Line(book, () => b.message('Testing.'), stringTitle: 'Test');
/// ```
class Line {
  /// Create a line.
  Line(
    this.book,
    this.func,
    {
      this.titleString,
      this.titleFunc,
      this.soundUrl,
    }
  );

  /// A line that acts as a checkbox.
  ///
  /// When activated, this line will call [setValue], with the negated result of [getValue].
  static Line checkboxLine(
    Book book, TitleFunctionType titleFunc, bool Function() getValue, void Function(bool) setValue, {
      String enableUrl = 'sounds/menus/enable.wav',
      String disableUrl = 'sounds/menus/disable.wav',
    }
  ) => Line(book, () {
    final bool value = !getValue();
    final String soundUrl = value ? enableUrl : disableUrl;
    book.options.soundPool.playSound(soundUrl, output: book.options.soundPool.output);
    setValue(value);
  }, titleFunc: titleFunc);

  /// The book which this line is bound to, via a [Page] instance.
  Book book;

  /// The function which will be called when this line is in focus, and [Book.activate] is called.
  BookFunctionType func;

  /// The title of this menu item as a string.
  String titleString;

  /// A function which when called should return the title of this line. Useful in circumstances where the title might change. On a configuration page for example.
  TitleFunctionType titleFunc;

  /// A function which should return the URL of the sound to play when this line is selected.
  TitleFunctionType soundUrl;

  /// Returns the title of this item as a string.
  ///
  /// If [titleFunc] is null, then [titleString] is returns. Otherwise, [titleFunc] is called.
  String getTitle() {
    if (titleString == null) {
      return titleFunc();
    }
    return titleString;
  }
}

/// A page of [Line] instances.
class Page {
  /// Create a page.
  ///
  /// if [dismissible] is true, then [Book.cancel] will dismiss it without any fuss.
  Page(
    {
      this.titleString, this.titleFunc,
      this.lines = const <Line>[],
      this.dismissible = true, this.playDefaultSounds = true, this.onCancel
    }
  );

  /// Create a page that can be used for confirmations.
  static Page confirmPage(
    Book book, BookFunctionType okFunc, {
      String title = 'Are you sure?',
      String okTitle = 'OK',
      String cancelTitle = 'Cancel',
      BookFunctionType cancelFunc,
    }
  ) {
    final List<Line> lines = <Line>[
      Line(
        book,
        okFunc,
        titleString: okTitle,
      ),
      Line(
        book,
        cancelFunc ?? () => book.pop(),
        titleString: cancelTitle,
      )
    ];
    return Page(
      titleString: title,
      lines: lines,
      onCancel: cancelFunc
    );
  }

  /// Creates a page which lists all [Hotkey] instances, bound to a [Keyboard] instance.
  ///
  /// The [beforeRun] function is called before running any hotkeys.
  static Page hotkeysPage(List<Hotkey> hotkeys, Book book, {String title, void Function() beforeRun, void Function() onCancel}) {
    final List<Line> lines = <Line>[];
    title ??= 'Hotkeys (${hotkeys.length})';
    for (final Hotkey hk in hotkeys) {
      lines.add(
        Line(
          book,
          () {
            if (beforeRun != null) {
              beforeRun();
            }
            hk.run();
          },
          titleFunc: () => '${hk.state}: ${hk.getTitle()}',
        )
      );
    }
    return Page(titleString: title, lines: lines, onCancel: onCancel);
  }

  /// Create a page for selecting an ambience.
  static Page soundsPage(
    Book book, List<String>sounds,
    void Function(String) onOk, String Function(String) getUrl, {
      String title, String currentSound, bool allowNull = true
    }
  ) {
    final List<Line> lines = <Line>[];
    if (allowNull) {
      lines.add(
        Line(book, () {
          onOk(null);
        }, titleString: 'Clear')
      );
    }
    for (final String sound in sounds) {
      lines.add(
        Line(
          book, () => onOk(sound),
          titleString: '${sound == currentSound ? "* " : ""}$sound',
          soundUrl: () => getUrl(sound)
        )
      );
    }
    title ??= 'Sounds (${lines.length})';
    return Page(titleString: title, lines: lines, playDefaultSounds: false);
  }

  /// The function to call when [Book.cancel] is called.
  void Function() onCancel;

  /// If true, then any [Line] instances contained by this page will not be silent, even if their [Line.soundUrl] attributes are null.
  bool playDefaultSounds;

  /// If true, then [Book.cancel] will dismiss this page.
  final bool dismissible;

  /// The current position in this page's list of [Line] instances.
  int focus = -1;

  /// The lines contained by this page.
  final List<Line> lines;

  /// The title of this page as a string.
  String titleString;

  /// A function which when called, will return the title of this page.
  TitleFunctionType titleFunc;

  /// Get the title of this page as a string. If [titleString] is null, then [titleFunc] will be called. Otherwise, [titleString] will be returned.
  String getTitle() {
    if (titleString == null) {
      return titleFunc();
    }
    return titleString;
  }

  /// Get the currently focussed line.
  Line getLine() {
    if (focus == -1) {
      return null;
    }
    return lines[focus];
  }
}
