class ColumnData {
  final String id;
  final String label;
  final int order;

  const ColumnData({
    required this.id,
    required this.label,
    required this.order,
  });

  factory ColumnData.fromJson(Map<String, dynamic> json) => ColumnData(
        id: json['id'] as String,
        label: json['label'] as String,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}
