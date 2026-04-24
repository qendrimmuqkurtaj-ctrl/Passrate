extension NumExtensions on num {
  bool get isEvenNumber => this % 2 == 0;
  String toCurrency({String symbol = "\$"}) => "$symbol${toStringAsFixed(2)}";
}
