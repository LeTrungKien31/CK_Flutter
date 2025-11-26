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

    try {
      _connection = PostgreSQLConnection(
        'localhost', // Thay bằng host của bạn
        5432, // Port
        'house_rent_db', // Tên database
        username: 'postgres', // Username
        password: '123', // Password
      );

      await _connection!.open();
      // ignore: avoid_print
      print('✅ Database connected successfully');
      return _connection!;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Database connection error: $e');
      rethrow;
    }
  }

  // Đóng kết nối
  Future<void> closeConnection() async {
    if (_connection != null && _connection!.isClosed == false) {
      await _connection!.close();
      // ignore: avoid_print
      print('Database connection closed');
    }
  }

  // Khởi tạo database
  Future<void> initDatabase() async {
    try {
      final conn = await connection;
      // ignore: avoid_print
      print('🔧 Initializing database...');

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
      // ignore: avoid_print
      print('✅ Table users created/exists');

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
      // ignore: avoid_print
      print('✅ Table houses created/exists');

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
      // ignore: avoid_print
      print('✅ Table bookings created/exists');

      // Insert dữ liệu mẫu cho houses
      await _insertSampleHouses(conn);
      
      // ignore: avoid_print
      print('✅ Database initialization completed');
    } catch (e) {
      // ignore: avoid_print  
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> _insertSampleHouses(PostgreSQLConnection conn) async {
    try {
      // Kiểm tra xem đã có dữ liệu chưa
      final countResult = await conn.query('SELECT COUNT(*) FROM houses');
      final count = countResult.first[0] as int;
      
      if (count > 0) {
        // ignore: avoid_print
        print('ℹ️ Sample houses already exist ($count houses)');
        return;
      }

      // ignore: avoid_print
      print('📝 Inserting sample houses...');

      // Insert từng house để dễ debug
      final houses = [
        {
          'name': 'The Moon House',
          'address': 'P455, Chhatak, Sylhet',
          'image_url': 'assets/images/house01.jpeg',
          'price': 4455.00,
          'area': 500.0,
          'bedrooms': 5,
          'bathrooms': 5,
          'kitchens': 2,
          'parking': 5,
          'description': 'Beautiful house with modern amenities'
        },
        {
          'name': 'Sunset Villa',
          'address': '123 Beach Road, Sylhet',
          'image_url': 'assets/images/house02.jpeg',
          'price': 5200.00,
          'area': 600.0,
          'bedrooms': 6,
          'bathrooms': 4,
          'kitchens': 2,
          'parking': 6,
          'description': 'Luxury villa near the beach'
        },
        {
          'name': 'Garden Paradise',
          'address': '789 Green Street, Sylhet',
          'image_url': 'assets/images/offer01.jpeg',
          'price': 3800.00,
          'area': 450.0,
          'bedrooms': 4,
          'bathrooms': 3,
          'kitchens': 1,
          'parking': 4,
          'description': 'Cozy house with beautiful garden'
        },
        {
          'name': 'Modern Loft',
          'address': '456 Downtown Ave, Sylhet',
          'image_url': 'assets/images/offer02.jpeg',
          'price': 3200.00,
          'area': 400.0,
          'bedrooms': 3,
          'bathrooms': 2,
          'kitchens': 1,
          'parking': 3,
          'description': 'Contemporary design in city center'
        }
      ];

      for (var house in houses) {
        await conn.query(
          '''
          INSERT INTO houses (name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description, is_available)
          VALUES (@name, @address, @imageUrl, @price, @area, @bedrooms, @bathrooms, @kitchens, @parking, @description, true)
          ''',
          substitutionValues: {
            'name': house['name'],
            'address': house['address'],
            'imageUrl': house['image_url'],
            'price': house['price'],
            'area': house['area'],
            'bedrooms': house['bedrooms'],
            'bathrooms': house['bathrooms'],
            'kitchens': house['kitchens'],
            'parking': house['parking'],
            'description': house['description'],
          },
        );
        // ignore: avoid_print
        print('  ✅ Inserted: ${house['name']}');
      }

      // ignore: avoid_print
      print('✅ All sample houses inserted successfully');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error inserting sample houses: $e');
      rethrow;
    }
  }

  // Thêm method để kiểm tra dữ liệu
  Future<void> checkData() async {
    try {
      final conn = await connection;
      
      final houses = await conn.query('SELECT COUNT(*) FROM houses');
      final users = await conn.query('SELECT COUNT(*) FROM users');
      final bookings = await conn.query('SELECT COUNT(*) FROM bookings');
      
      // ignore: avoid_print
      print('\n📊 Database Status:');
      // ignore: avoid_print
      print('  Houses: ${houses.first[0]}');
      // ignore: avoid_print
      print('  Users: ${users.first[0]}');
      // ignore: avoid_print
      print('  Bookings: ${bookings.first[0]}');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error checking data: $e');
    }
  }
}