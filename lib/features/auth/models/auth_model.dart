class AuthModel {
  final String id;
  final String name;
  final String email;
  final String bio;
  final String? profileImage;
  final String token;

  AuthModel({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    this.profileImage,
    required this.token,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profileImage:
          json['image'] as String? ??
          json['profileImage'] as String? ??
          json['imageUrl'] as String?,
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'bio': bio,
    'image': profileImage,
    'token': token,
  };
}
