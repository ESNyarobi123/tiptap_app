num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}

class DashboardStats {
  final num tipsToday;
  final num tipsThisWeek;
  final int myActiveOrders;
  final int restaurantActiveOrders;
  final int readyToServe;
  final int pendingRequests;

  DashboardStats({
    required this.tipsToday,
    required this.tipsThisWeek,
    required this.myActiveOrders,
    required this.restaurantActiveOrders,
    required this.readyToServe,
    required this.pendingRequests,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      tipsToday: _parseNum(json['tips_today']),
      tipsThisWeek: _parseNum(json['tips_this_week']),
      myActiveOrders: _parseNum(json['my_active_orders']).toInt(),
      restaurantActiveOrders: _parseNum(
        json['restaurant_active_orders'],
      ).toInt(),
      readyToServe: _parseNum(json['ready_to_serve']).toInt(),
      pendingRequests: _parseNum(json['pending_requests']).toInt(),
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final num? price;

  OrderItem({required this.name, required this.quantity, this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final p = json['price'];
    return OrderItem(
      name: json['name'] as String? ?? 'Custom Order',
      quantity: (json['quantity'] ?? 1) is int
          ? (json['quantity'] ?? 1) as int
          : int.tryParse('${json['quantity']}') ?? 1,
      price: p == null ? null : _parseNum(p),
    );
  }
}

class UnassignedOrder {
  final int id;
  final String tableNumber;
  final String status;
  final num totalAmount;
  final String createdAt;
  final List<OrderItem> items;

  UnassignedOrder({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory UnassignedOrder.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return UnassignedOrder(
      id: json['id'] as int,
      tableNumber: (json['table_number'] ?? '?').toString(),
      status: json['status'] as String? ?? 'pending',
      totalAmount: _parseNum(json['total_amount']),
      createdAt: json['created_at'] as String? ?? '',
      items: itemsList
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PendingRequest {
  final int id;
  final String type;
  final String? tableNumber;
  final String createdAt;

  PendingRequest({
    required this.id,
    required this.type,
    this.tableNumber,
    required this.createdAt,
  });

  String get displayType =>
      type == 'request_bill' ? 'Request Bill' : 'Call Waiter';
  String get tableDisplay => tableNumber ?? 'General Area / Mapokezi';

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'call_waiter',
      tableNumber: json['table_number']?.toString(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class RecentFeedback {
  final int id;
  final int rating;
  final String? comment;
  final String createdAt;

  RecentFeedback({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory RecentFeedback.fromJson(Map<String, dynamic> json) {
    return RecentFeedback(
      id: json['id'] as int,
      rating: (json['rating'] ?? 0) as int,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class MyOrderToday {
  final int id;
  final String tableNumber;
  final String status;
  final num totalAmount;
  final int itemsCount;
  final String createdAt;

  MyOrderToday({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.totalAmount,
    required this.itemsCount,
    required this.createdAt,
  });

  factory MyOrderToday.fromJson(Map<String, dynamic> json) {
    return MyOrderToday(
      id: json['id'] as int,
      tableNumber: (json['table_number'] ?? '?').toString(),
      status: json['status'] as String? ?? 'pending',
      totalAmount: _parseNum(json['total_amount']),
      itemsCount: (json['items_count'] ?? 0) is int
          ? (json['items_count'] ?? 0) as int
          : int.tryParse('${json['items_count']}') ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
