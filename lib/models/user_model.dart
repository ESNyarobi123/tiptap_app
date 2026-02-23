class UserModel {
  final int id;
  final String name;
  final String email;
  final int? restaurantId;
  final String? restaurantName;
  final String? restaurantLocation;
  final String? waiterCode;
  final String? globalWaiterNumber;
  final String? waiterQrUrl;
  final bool isLinked;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.restaurantId,
    this.restaurantName,
    this.restaurantLocation,
    this.waiterCode,
    this.globalWaiterNumber,
    this.waiterQrUrl,
    this.isLinked = true,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      restaurantId: json['restaurant_id'] as int?,
      restaurantName: json['restaurant_name'] as String?,
      restaurantLocation: json['restaurant_location'] as String?,
      waiterCode: json['waiter_code'] as String?,
      globalWaiterNumber: json['global_waiter_number'] as String?,
      waiterQrUrl: json['waiter_qr_url'] as String?,
      isLinked: json['is_linked'] as bool? ?? (json['restaurant_id'] != null),
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
