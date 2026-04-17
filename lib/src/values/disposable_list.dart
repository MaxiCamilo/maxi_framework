import 'package:maxi_framework/maxi_framework.dart';

class DisposableList<T extends Disposable> with DisposableMixin, LifecycleHub implements List<T> {
  final List<T> _items;
  final bool disposeIfItsEmpty;

  DisposableList({List<T>? initialItems, this.disposeIfItsEmpty = false}) : _items = initialItems ?? [];

  @override
  void performObjectDiscard() {
    for (final item in _items) {
      item.dispose();
    }
    _items.clear();
  }

  void _joinObject(T item) {
    if (item.itWasDiscarded) {
      throw NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'Cannot add the object to the list because it was discarded'),
      );
    }

    resurrectObject();
    lifecycleScope.joinDisposableObject(item, () {
      if (itWasDiscarded) return;
      _items.remove(item);
      if (disposeIfItsEmpty && _items.isEmpty) {
        dispose();
      }
    });
  }

  // ── read-only delegation ────────────────────────────────────────────────

  @override
  int get length => _items.length;

  @override
  T operator [](int index) => _items[index];

  @override
  Iterator<T> get iterator => _items.iterator;

  @override
  List<T> operator +(List<T> other) => _items + other;

  @override
  bool any(bool Function(T element) test) => _items.any(test);

  @override
  Map<int, T> asMap() => _items.asMap();

  @override
  List<R> cast<R>() => _items.cast<R>();

  @override
  bool contains(Object? element) => _items.contains(element);

  @override
  T elementAt(int index) => _items.elementAt(index);

  @override
  bool every(bool Function(T element) test) => _items.every(test);

  @override
  Iterable<S> expand<S>(Iterable<S> Function(T element) toElements) => _items.expand(toElements);

  @override
  T get first => _items.first;

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) => _items.firstWhere(test, orElse: orElse);

  @override
  S fold<S>(S initialValue, S Function(S previousValue, T element) combine) => _items.fold(initialValue, combine);

  @override
  Iterable<T> followedBy(Iterable<T> other) => _items.followedBy(other);

  @override
  void forEach(void Function(T element) action) => _items.forEach(action);

  @override
  Iterable<T> getRange(int start, int end) => _items.getRange(start, end);

  @override
  int indexOf(T element, [int start = 0]) => _items.indexOf(element, start);

  @override
  int indexWhere(bool Function(T element) test, [int start = 0]) => _items.indexWhere(test, start);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  String join([String separator = '']) => _items.join(separator);

  @override
  T get last => _items.last;

  @override
  int lastIndexOf(T element, [int? start]) => _items.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) => _items.lastIndexWhere(test, start);

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) => _items.lastWhere(test, orElse: orElse);

  @override
  Iterable<S> map<S>(S Function(T e) toElement) => _items.map(toElement);

  @override
  T reduce(T Function(T value, T element) combine) => _items.reduce(combine);

  @override
  T get single => _items.single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) => _items.singleWhere(test, orElse: orElse);

  @override
  Iterable<T> skip(int count) => _items.skip(count);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _items.skipWhile(test);

  @override
  List<T> sublist(int start, [int? end]) => _items.sublist(start, end);

  @override
  Iterable<T> take(int count) => _items.take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _items.takeWhile(test);

  @override
  List<T> toList({bool growable = true}) => _items.toList(growable: growable);

  @override
  Set<T> toSet() => _items.toSet();

  @override
  Iterable<T> where(bool Function(T element) test) => _items.where(test);

  @override
  Iterable<S> whereType<S>() => _items.whereType<S>();

  @override
  List<T> get reversed => _items.reversed.toList();

  // ── mutating: no disposal needed ───────────────────────────────────────

  @override
  void add(T value) {
    _joinObject(value);
    _items.add(value);
  }

  @override
  void addAll(Iterable<T> iterable) {
    final list = iterable.toList();
    list.lambda(_joinObject);
    _items.addAll(list);
  }

  @override
  void insert(int index, T element) {
    _joinObject(element);
    _items.insert(index, element);
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    final list = iterable.toList();
    list.lambda(_joinObject);
    _items.insertAll(index, list);
  }

  @override
  void sort([int Function(T a, T b)? compare]) {
    resurrectObject();
    _items.sort(compare);
  }

  @override
  void shuffle([dynamic random]) {
    resurrectObject();
    _items.shuffle(random);
  }

  @override
  void fillRange(int start, int end, [T? fillValue]) {
    resurrectObject();
    _items.fillRange(start, end, fillValue);
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    final list = iterable.toList();
    list.lambda(_joinObject);
    _items.setRange(start, end, list, skipCount);
  }

  @override
  void setAll(int index, Iterable<T> iterable) {
    final list = iterable.toList();
    list.lambda(_joinObject);
    _items.setAll(index, list);
  }

  // ── mutating: dispose replaced/removed items ────────────────────────────

  @override
  set length(int newLength) {
    if (newLength < _items.length) {
      for (int i = newLength; i < _items.length; i++) {
        _items[i].dispose();
      }
    }
    _items.length = newLength;
  }

  @override
  void operator []=(int index, T value) {
    final before = _items[index];
    _joinObject(value);
    _items[index] = value;
    before.dispose();
  }

  @override
  bool remove(Object? value) {
    final index = value is T ? _items.indexOf(value) : -1;
    if (index == -1) return false;
    _items[index].dispose();
    return true;
  }

  @override
  T removeAt(int index) {
    final item = _items[index];
    item.dispose();
    _items.removeAt(index);
    return item;
  }

  @override
  T removeLast() {
    final item = _items.removeLast();
    item.dispose();
    return item;
  }

  @override
  void removeRange(int start, int end) {
    for (int i = start; i < end; i++) {
      _items[i].dispose();
    }
    _items.removeRange(start, end);
  }

  @override
  void removeWhere(bool Function(T element) test) {
    for (final item in _items.where(test).toList()) {
      item.dispose();
    }
    _items.removeWhere(test);
  }

  @override
  void retainWhere(bool Function(T element) test) {
    for (final item in _items.where((e) => !test(e)).toList()) {
      item.dispose();
    }
    _items.retainWhere(test);
  }

  @override
  void clear() {
    final clone = _items.toList();
    _items.clear();
    for (final item in clone) {
      item.dispose();
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<T> replacements) {
    for (int i = start; i < end; i++) {
      _items[i].dispose();
    }
    _items.replaceRange(start, end, replacements);
  }

  @override
  set first(T value) {
    T? before;
    if (_items.isNotEmpty) {
      before = _items.first;
    }

    _joinObject(value);
    _items.first = value;

    before?.dispose();
  }

  @override
  set last(T value) {
    T? before;
    if (_items.isNotEmpty) {
      before = _items.last;
    }

    _joinObject(value);
    _items.last = value;

    before?.dispose();
  }
}
