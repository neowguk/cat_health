class CatRecord {
  final int? id;
  final String catName;
  final double weight;
  final double temperature;
  final DateTime timestamp;

  CatRecord({
    this.id,
    required this.catName,
    required this.weight,
    this.temperature = 0.0,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'catName': catName,
        'weight': weight,
        'temperature': temperature,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory CatRecord.fromMap(Map<String, dynamic> map) => CatRecord(
        id: map['id'] as int?,
        catName: map['catName'] as String,
        weight: (map['weight'] as num).toDouble(),
        temperature: (map['temperature'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );

  CatRecord copyWith({
    int? id,
    String? catName,
    double? weight,
    double? temperature,
    DateTime? timestamp,
  }) =>
      CatRecord(
        id: id ?? this.id,
        catName: catName ?? this.catName,
        weight: weight ?? this.weight,
        temperature: temperature ?? this.temperature,
        timestamp: timestamp ?? this.timestamp,
      );
}
