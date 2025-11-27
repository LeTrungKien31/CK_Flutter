import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
        '10.0.2.2', // Host cho emulator Android (localhost máy thật)
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

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Khởi tạo database
  Future<void> initDatabase() async {
    try {
      final conn = await connection;
      // ignore: avoid_print
      print('🔧 Initializing database...');

      // Tạo bảng users với cột role
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          email VARCHAR(255) UNIQUE NOT NULL,
          password VARCHAR(255) NOT NULL,
          full_name VARCHAR(255),
          phone VARCHAR(20),
          address TEXT,
          avatar_path TEXT,
          role VARCHAR(20) DEFAULT 'user',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      // ignore: avoid_print
      print('✅ Table users created/exists');

      // Đảm bảo cột role tồn tại (cho trường hợp DB cũ không có cột này)
      try {
        await conn.execute('''
          ALTER TABLE users
          ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';
        ''');
        // ignore: avoid_print
        print('✅ Role column checked/added');
      } catch (e) {
        // ignore: avoid_print
        print('ℹ️ Role column may already exist: $e');
      }

      // Tạo admin mặc định nếu chưa tồn tại
      await _createDefaultAdmin(conn);

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

  Future<void> _createDefaultAdmin(PostgreSQLConnection conn) async {
    try {
      // Kiểm tra xem đã có admin chưa
      final adminCheck = await conn.query(
        "SELECT id FROM users WHERE role = 'admin' LIMIT 1",
      );

      if (adminCheck.isEmpty) {
        // ignore: avoid_print
        print('📝 Creating default admin account...');

        // Tạo admin với:
        // Email: admin@house.com
        // Password: admin123
        final hashedPassword = _hashPassword('admin123');

        await conn.query(
          '''
          INSERT INTO users (email, password, full_name, phone, role)
          VALUES (@email, @password, @fullName, @phone, 'admin')
          RETURNING id
          ''',
          substitutionValues: {
            'email': 'admin@house.com',
            'password': hashedPassword,
            'fullName': 'Administrator',
            'phone': '0000000000',
          },
        );

        // ignore: avoid_print
        print('✅ Default admin created:');
        // ignore: avoid_print
        print('   Email: admin@house.com');
        // ignore: avoid_print
        print('   Password: admin123');
      } else {
        // ignore: avoid_print
        print('ℹ️ Admin account already exists');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error creating admin: $e');
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
          'description':
              'Beautiful house with modern amenities and stunning moon views'
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
          'description':
              'Luxury villa near the beach with breathtaking sunset views'
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
          'description':
              'Cozy house with beautiful garden and peaceful surroundings'
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
          'description':
              'Contemporary design in city center with all modern facilities'
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
      final admins =
          await conn.query("SELECT COUNT(*) FROM users WHERE role = 'admin'");

      // ignore: avoid_print
      print('\n📊 Database Status:');
      // ignore: avoid_print
      print('  Houses: ${houses.first[0]}');
      // ignore: avoid_print
      print('  Users: ${users.first[0]}');
      // ignore: avoid_print
      print('  Admins: ${admins.first[0]}');
      // ignore: avoid_print
      print('  Bookings: ${bookings.first[0]}');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error checking data: $e');
    }
  }
}
