class House {
  int? id;
  String name;
  String address;
  String imageUrl;
  double? price;
  double? area;
  int? bedrooms;
  int? bathrooms;
  int? kitchens;
  int? parking;
  String? description;
  bool? isAvailable;

  House({
    this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    this.price,
    this.area,
    this.bedrooms,
    this.bathrooms,
    this.kitchens,
    this.parking,
    this.description,
    this.isAvailable,
  });

  // Constructor từ database
  factory House.fromDatabase(dynamic row) {
    return House(
      id: row[0] as int,
      name: row[1] as String,
      address: row[2] as String,
      imageUrl: row[3] as String? ?? 'assets/images/house01.jpeg',
      price: (row[4] as num?)?.toDouble(),
      area: (row[5] as num?)?.toDouble(),
      bedrooms: row[6] as int?,
      bathrooms: row[7] as int?,
      kitchens: row[8] as int?,
      parking: row[9] as int?,
      description: row[10] as String?,
      isAvailable: row[11] as bool?,
    );
  }

  // Dữ liệu mẫu (fallback)
  static List<House> generateRecommended() {
    return [
      House(
        name: 'The Moon House',
        address: 'P455, Chhatak, Sylhet',
        imageUrl: 'assets/images/house01.jpeg',
        price: 4455,
        area: 500,
      ),
      House(
        name: 'Sunset Villa',
        address: 'P455, Chhatak, Sylhet',
        imageUrl: 'assets/images/house02.jpeg',
        price: 5200,
        area: 600,
      ),
    ];
  }

  static List<House> generateBestOffer() {
    return [
      House(
        name: 'Garden Paradise',
        address: 'P455, Chhatak, Sylhet',
        imageUrl: 'assets/images/offer01.jpeg',
        price: 3800,
        area: 450,
      ),
      House(
        name: 'Modern Loft',
        address: 'P455, Chhatak, Sylhet',
        imageUrl: 'assets/images/offer02.jpeg',
        price: 3200,
        area: 400,
      ),
    ];
  }
}