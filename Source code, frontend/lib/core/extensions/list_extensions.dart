extension ListExtensions<T> on List<T> {
  List<T> removeDuplicates() => toSet().toList();
  List<T> shuffled() => <T>[...this]..shuffle();
}
