class BlogModel {
  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final String description;
  final String status;
  final List<String> tags;
  final bool isFeatured;
  final String metaTitle;
  final String metaDescription;
  final DateTime publishedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.status,
    required this.tags,
    required this.isFeatured,
    required this.metaTitle,
    required this.metaDescription,
    required this.publishedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      imageUrl: json['image'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'published',
      tags: json['tags'] is List ? List<String>.from(json['tags'] as List) : [],
      isFeatured: (json['isFeatured'] as bool?) ?? false,
      metaTitle: json['metaTitle'] as String? ?? '',
      metaDescription: json['metaDescription'] as String? ?? '',
      publishedDate: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'imageUrl': imageUrl,
    'category': category,
    'description': description,
    'status': status,
    'tags': tags,
    'isFeatured': isFeatured,
    'metaTitle': metaTitle,
    'metaDescription': metaDescription,
    'publishedDate': publishedDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
