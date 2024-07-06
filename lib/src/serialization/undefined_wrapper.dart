/// A wrapper around a type that can be undefined.
///
/// Note that the type itself can be nullable, which is irrelevant.
///
/// An undefined value semantically means that the key was not present in
/// the source Map when deserializing the class, but it can be used in other
/// contexts as well.
///
/// usage:
/// ```dart
/// final x = UndefinedWrapper<int>(10);
/// final y = UndefinedWrapper<int>.undefined();
/// ```
extension type const UndefinedWrapper<T>._(Object? source) {
  static const $undefinedToken = _UndefinedClass();

  const UndefinedWrapper.undefined() : this._($undefinedToken);
  const UndefinedWrapper(T source) : this._(source);

  bool get isUndefined => source == $undefinedToken || source is! T;
  bool get isDefined => source != $undefinedToken && source is T;

  /// This returns the source value, or null if it's undefined.
  T? get valueOrNull => isUndefined ? null : source as T;

  /// This returns the source value, and throws an exception if it's undefined.
  T get valueRequired => isUndefined
      ? throw ArgumentError('Value is required, but it is undefined.')
      : source as T;

  bool equals(UndefinedWrapper<T> other) {
    return other.source == source;
  }

  UndefinedWrapper<TOther> map<TOther>(TOther Function(T src) mapper) {
    if (isUndefined) {
      return const UndefinedWrapper.undefined();
    } else {
      return UndefinedWrapper(mapper(valueRequired));
    }
  }

  TOther split<TOther>({
    required TOther Function(T src) defined,
    required TOther Function() unDefined,
  }) {
    if (isDefined) {
      return defined(source as T);
    } else {
      return unDefined();
    }
  }
}

class _UndefinedClass {
  const _UndefinedClass();

  @override
  String toString() {
    return "Undefined.";
  }
}
