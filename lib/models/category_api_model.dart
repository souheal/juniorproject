class CategoryApiModel {
  final int id;
  final String name;

  CategoryApiModel({
    required this.id,
    required this.name,
  });

  factory CategoryApiModel.fromJson(Map<String, dynamic> json) {
    return CategoryApiModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => name;
}
