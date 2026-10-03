class FieldItem {
  final String sku;
  final String title;
  final String category;
  final List<String> applicableFaults;
  int quantity;

  FieldItem({
    required this.sku,
    required this.title,
    required this.category,
    this.applicableFaults = const [],
    this.quantity = 0,
  });

  Map<String, dynamic> toMap() => {'sku': sku, 'quantity': quantity};
}