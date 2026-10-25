double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
double? _dn(dynamic v) => v == null ? null : _d(v);

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.vehicle,
    this.businessId,
    this.businessName,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? vehicle;
  final int? businessId;
  final String? businessName;

  bool get isDriver => role == 'repartidor';
  bool get isBusiness => role == 'negocio';

  String get roleLabel => switch (role) {
    'repartidor' => 'Repartidor',
    'negocio' => 'Negocio',
    _ => 'Cliente',
  };

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'],
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    role: j['role'] ?? 'cliente',
    phone: j['phone'],
    vehicle: j['vehicle'],
    businessId: j['business_id'],
    businessName: j['business']?['name'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'vehicle': vehicle,
    'business_id': businessId,
    if (businessName != null) 'business': {'name': businessName},
  };
}

class Category {
  Category({required this.id, required this.name, required this.icon, required this.color});

  final int id;
  final String name;
  final String icon;
  final String color;

  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'], name: j['name'], icon: j['icon'] ?? 'store', color: j['color'] ?? '#10B981');
}

class Product {
  Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.section,
    required this.price,
    this.description,
    this.imageUrl,
    this.available = true,
  });

  final int id;
  final int businessId;
  final String name;
  final String section;
  final double price;
  final String? description;
  final String? imageUrl;
  final bool available;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    businessId: j['business_id'],
    name: j['name'],
    section: j['section'] ?? 'General',
    price: _d(j['price']),
    description: j['description'],
    imageUrl: j['image_url'],
    available: j['available'] ?? true,
  );
}

class Business {
  Business({
    required this.id,
    required this.name,
    this.description,
    this.categoryName,
    this.logoUrl,
    this.coverUrl,
    this.address,
    this.phone,
    this.bankInfo,
    this.lat,
    this.lng,
    this.deliveryFee = 0,
    this.minOrder = 0,
    this.timeMin = 20,
    this.timeMax = 40,
    this.rating = 0,
    this.ratingCount = 0,
    this.isOpen = true,
    this.commissionRate = 0,
    this.opensAt,
    this.closesAt,
    this.featured = false,
    this.products = const [],
  });

  final int id;
  final String name;
  final String? description;
  final String? categoryName;
  final String? logoUrl;
  final String? coverUrl;
  final String? address;
  final String? phone;
  final String? bankInfo;
  final double? lat;
  final double? lng;
  final double deliveryFee;
  final double minOrder;
  final int timeMin;
  final int timeMax;
  final double rating;
  final int ratingCount;

  /// Abierto ahora: respeta la pausa manual y el horario de atención.
  final bool isOpen;
  final double commissionRate;
  final String? opensAt;
  final String? closesAt;
  final bool featured;
  final List<Product> products;

  String get timeLabel => '$timeMin-$timeMax min';
  String? get hoursLabel => opensAt != null && closesAt != null ? '${opensAt!.substring(0, 5)} – ${closesAt!.substring(0, 5)}' : null;

  factory Business.fromJson(Map<String, dynamic> j) => Business(
    id: j['id'],
    name: j['name'] ?? '',
    description: j['description'],
    categoryName: j['category']?['name'],
    logoUrl: j['logo_url'],
    coverUrl: j['cover_url'],
    address: j['address'],
    phone: j['phone'],
    bankInfo: j['bank_info'],
    lat: _dn(j['lat']),
    lng: _dn(j['lng']),
    deliveryFee: _d(j['delivery_fee']),
    minOrder: _d(j['min_order']),
    timeMin: j['time_min'] ?? 20,
    timeMax: j['time_max'] ?? 40,
    rating: _d(j['rating']),
    ratingCount: j['rating_count'] ?? 0,
    isOpen: j['open_now'] ?? j['is_open'] ?? true,
    commissionRate: _d(j['commission_rate']),
    opensAt: j['opens_at'],
    closesAt: j['closes_at'],
    featured: j['featured'] ?? false,
    products: (j['products'] as List? ?? []).map((p) => Product.fromJson(p)).toList(),
  );
}

class Address {
  Address({this.id, required this.label, required this.address, this.reference, required this.lat, required this.lng});

  final int? id;
  final String label;
  final String address;
  final String? reference;
  final double lat;
  final double lng;

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['id'],
    label: j['label'] ?? '',
    address: j['address'] ?? '',
    reference: j['reference'],
    lat: _d(j['lat']),
    lng: _d(j['lng']),
  );

  Map<String, dynamic> toJson() => {'label': label, 'address': address, 'reference': reference, 'lat': lat, 'lng': lng};
}

class OrderItem {
  OrderItem({this.productId, required this.name, required this.price, required this.quantity, required this.subtotal, this.notes});

  final int? productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? notes;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    productId: j['product_id'],
    name: j['name'],
    price: _d(j['price']),
    quantity: j['quantity'],
    subtotal: _d(j['subtotal']),
    notes: j['notes'],
  );
}

class OrderStatus {
  static const labels = {
    'pendiente': 'Pendiente',
    'aceptado': 'Aceptado',
    'preparando': 'Preparando',
    'listo': 'Listo para recoger',
    'en_camino': 'En camino',
    'entregado': 'Entregado',
    'cancelado': 'Cancelado',
  };

  /// Pasos que ve el cliente en la línea de tiempo.
  static const steps = ['pendiente', 'aceptado', 'preparando', 'en_camino', 'entregado'];

  static String label(String s) => labels[s] ?? s;
}

class Order {
  Order({
    required this.id,
    required this.status,
    required this.address,
    required this.lat,
    required this.lng,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    this.couponCode,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.reference,
    this.cashAmount,
    this.notes,
    this.cancelReason,
    this.transferProofUrl,
    this.rating,
    this.ratingComment,
    this.business,
    this.items = const [],
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverLat,
    this.driverLng,
    this.clientName,
    this.clientPhone,
  });

  final int id;
  final String status;
  final String address;
  final String? reference;
  final double lat;
  final double lng;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String? couponCode;
  final double total;
  final String paymentMethod;
  final double? cashAmount;
  final String? notes;
  final String? cancelReason;
  final String? transferProofUrl;
  final int? rating;
  final String? ratingComment;
  final DateTime createdAt;
  final Business? business;
  final List<OrderItem> items;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final double? driverLat;
  final double? driverLng;
  final String? clientName;
  final String? clientPhone;

  bool get isActive => status != 'entregado' && status != 'cancelado';
  bool get isTransfer => paymentMethod == 'transferencia';
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  /// JSON original, para crear copias con cambios puntuales.
  late final Map<String, dynamic> raw;

  /// El mismo pedido con la nueva posición del repartidor (evento en tiempo real).
  Order withDriverAt(double lat, double lng) => Order.fromJson({...raw, 'driver_lat': lat, 'driver_lng': lng});

  factory Order.fromJson(Map<String, dynamic> j) => Order._fromJson(j)..raw = j;

  factory Order._fromJson(Map<String, dynamic> j) => Order(
    id: j['id'],
    status: j['status'],
    address: j['address'] ?? '',
    reference: j['reference'],
    lat: _d(j['lat']),
    lng: _d(j['lng']),
    subtotal: _d(j['subtotal']),
    deliveryFee: _d(j['delivery_fee']),
    discount: _d(j['discount']),
    couponCode: j['coupon_code'],
    total: _d(j['total']),
    paymentMethod: j['payment_method'] ?? 'efectivo',
    cashAmount: _dn(j['cash_amount']),
    notes: j['notes'],
    cancelReason: j['cancel_reason'],
    transferProofUrl: j['transfer_proof_url'],
    rating: j['rating'],
    ratingComment: j['rating_comment'],
    createdAt: DateTime.tryParse(j['created_at'] ?? '')?.toLocal() ?? DateTime.now(),
    business: j['business'] != null ? Business.fromJson(j['business']) : null,
    items: (j['items'] as List? ?? []).map((i) => OrderItem.fromJson(i)).toList(),
    driverName: j['driver']?['name'],
    driverPhone: j['driver']?['phone'],
    driverVehicle: j['driver']?['vehicle'],
    driverLat: _dn(j['driver_lat']),
    driverLng: _dn(j['driver_lng']),
    clientName: j['user']?['name'],
    clientPhone: j['user']?['phone'],
  );
}
