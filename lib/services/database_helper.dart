import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  PostgreSQLConnection? _connection;

  // Cấu hình kết nối PostgreSQL
  Future<PostgreSQLConnection> get connection async {
    if (_connection != null && _connection!.isClosed == false) {
      return _connection!;
    }

    _connection = PostgreSQLConnection(
      'localhost', // Thay bằng host của bạn
      5432, // Port
      'house_rent_db', // Tên database
      username: 'postgres', // Username
      password: '123', // Password
    );

    await _connection!.open();
    return _connection!;
  }

  // Đóng kết nối
  Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
    }
  }

  // Khởi tạo database
  Future<void> initDatabase() async {
    final conn = await connection;

    // Tạo bảng users
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        full_name VARCHAR(255),
        phone VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tạo bảng houses
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS houses (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        address TEXT NOT NULL,
        image_url TEXT,
        price DECIMAL(10, 2) NOT NULL,
        area DECIMAL(10, 2),
        bedrooms INTEGER,
        bathrooms INTEGER,
        kitchens INTEGER,
        parking INTEGER,
        description TEXT,
        is_available BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tạo bảng bookings
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        house_id INTEGER REFERENCES houses(id),
        booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        check_in_date DATE NOT NULL,
        check_out_date DATE NOT NULL,
        total_price DECIMAL(10, 2),
        status VARCHAR(50) DEFAULT 'pending',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert dữ liệu mẫu cho houses
    await _insertSampleHouses(conn);
  }

  Future<void> _insertSampleHouses(PostgreSQLConnection conn) async {
    final count = await conn.query('SELECT COUNT(*) FROM houses');
    if (count.first[0] as int > 0) return;

    await conn.execute('''
      INSERT INTO houses (name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description)
      VALUES 
        ('The Moon House', 'P455, Chhatak, Sylhet', 'assets/images/house01.jpeg', 4455.00, 500, 5, 5, 2, 5, 'Beautiful house with modern amenities'),
        ('Sunset Villa', '123 Beach Road, Sylhet', 'assets/images/house02.jpeg', 5200.00, 600, 6, 4, 2, 6, 'Luxury villa near the beach'),
        ('Garden Paradise', '789 Green Street, Sylhet', 'assets/images/offer01.jpeg', 3800.00, 450, 4, 3, 1, 4, 'Cozy house with beautiful garden'),
        ('Modern Loft', '456 Downtown Ave, Sylhet', 'assets/images/offer02.jpeg', 3200.00, 400, 3, 2, 1, 3, 'Contemporary design in city center')
    ''');
  }
}
