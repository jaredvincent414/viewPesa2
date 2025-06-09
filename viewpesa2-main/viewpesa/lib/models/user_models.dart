class UserModel {
  final int? id;
  final String phoneNumber;
  final String? imagePath; // Nullable as per schema
  final String password;
  final String username;

  UserModel({
    this.id,
    required this.phoneNumber,
    required this.username,
    required this.password,
    this.imagePath, // Changed to optional since schema allows NULL
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password,
      'imagePath': imagePath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      phoneNumber: map['phoneNumber'],
      username: map['username'],
      password: map['password'] ?? '', // Fallback if not present
      imagePath: map['imagePath'],
    );
  }

  /// CopyWith method to create a new UserModel with updated fields
  UserModel copyWith({
    int? id,
    String? phoneNumber,
    String? username,
    String? password,
    String? imagePath,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      password: password ?? this.password,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, phoneNumber: $phoneNumber, username: $username, password: $password, imagePath: $imagePath)';
  }
}