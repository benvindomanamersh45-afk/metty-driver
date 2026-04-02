class Trip {
  final int id;
  final String passengerName;
  final String? driverName;
  final String pickupAddress;
  final String destinationAddress;
  final String category;
  final String status;
  final double price;
  final int? estimatedDuration;

  Trip({
    required this.id,
    required this.passengerName,
    this.driverName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.category,
    required this.status,
    required this.price,
    this.estimatedDuration,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? 0,
      passengerName: json['passenger_name'] ?? 'Desconhecido',
      driverName: json['driver_name'],
      pickupAddress: json['pickup_address'] ?? '',
      destinationAddress: json['destination_address'] ?? '',
      category: json['category'] ?? 'ECONOMIC',
      status: json['status'] ?? 'REQUESTED',
      price: (json['price'] ?? 0).toDouble(),
      estimatedDuration: json['estimated_duration'],
    );
  }

  String get categoryDisplay {
    switch (category) {
      case 'ECONOMIC': return 'Econômico';
      case 'COMFORT': return 'Conforto';
      case 'PREMIUM': return 'Premium';
      default: return category;
    }
  }
}
