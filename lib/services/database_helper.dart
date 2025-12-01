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
        '10.0.2.2',
        5432,
        'house_rent_db',
        username: 'postgres',
        password: '123',
      );

      await _connection!.open();
      print('✅ Kết nối database thành công');
      return _connection!;
    } catch (e) {
      print('❌ Lỗi kết nối database: $e');
      rethrow;
    }
  }

  Future<void> closeConnection() async {
    if (_connection != null && _connection!.isClosed == false) {
      await _connection!.close();
      print('Đã đóng kết nối database');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> initDatabase() async {
    try {
      final conn = await connection;
      print('🔧 Đang khởi tạo database...');

      // Tạo bảng users
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
      print('✅ Bảng users đã tạo/tồn tại');

      try {
        await conn.execute('''
          ALTER TABLE users
          ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';
        ''');
        print('✅ Đã kiểm tra/thêm cột role');
      } catch (e) {
        print('ℹ️ Cột role có thể đã tồn tại: $e');
      }

      await _createDefaultAdmin(conn);

      // Tạo bảng houses
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS houses (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          address TEXT NOT NULL,
          image_url TEXT,
          price DECIMAL(15, 2) NOT NULL,
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
      print('✅ Bảng houses đã tạo/tồn tại');

      // Tạo bảng bookings
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS bookings (
          id SERIAL PRIMARY KEY,
          user_id INTEGER REFERENCES users(id),
          house_id INTEGER REFERENCES houses(id),
          booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          check_in_date DATE NOT NULL,
          check_out_date DATE NOT NULL,
          total_price DECIMAL(15, 2),
          status VARCHAR(50) DEFAULT 'pending',
          notes TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      print('✅ Bảng bookings đã tạo/tồn tại');

      await _insertSampleHouses(conn);

      print('✅ Hoàn tất khởi tạo database');
    } catch (e) {
      print('❌ Lỗi khởi tạo database: $e');
      rethrow;
    }
  }

  Future<void> _createDefaultAdmin(PostgreSQLConnection conn) async {
    try {
      final adminCheck = await conn.query(
        "SELECT id FROM users WHERE role = 'admin' LIMIT 1",
      );

      if (adminCheck.isEmpty) {
        print('📝 Đang tạo tài khoản admin mặc định...');

        final hashedPassword = _hashPassword('admin123');

        await conn.query(
          '''
          INSERT INTO users (email, password, full_name, phone, role)
          VALUES (@email, @password, @fullName, @phone, 'admin')
          RETURNING id
          ''',
          substitutionValues: {
            'email': 'admin@nhasang.vn',
            'password': hashedPassword,
            'fullName': 'Quản Trị Viên',
            'phone': '0901234567',
          },
        );

        print('✅ Đã tạo tài khoản admin:');
        print('   Email: admin@nhasang.vn');
        print('   Mật khẩu: admin123');
      } else {
        print('ℹ️ Tài khoản admin đã tồn tại');
      }
    } catch (e) {
      print('❌ Lỗi tạo admin: $e');
    }
  }

  Future<void> _insertSampleHouses(PostgreSQLConnection conn) async {
    try {
      final countResult = await conn.query('SELECT COUNT(*) FROM houses');
      final count = countResult.first[0] as int;

      if (count > 0) {
        print('ℹ️ Dữ liệu mẫu đã tồn tại ($count nhà)');
        return;
      }

      print('📝 Đang thêm dữ liệu mẫu...');

      final houses = [
        {
          'name': 'Nhà Phố Hiện Đại Quận 1',
          'address': '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
          'image_url': 'assets/images/house01.jpeg',
          'price': 45000000.0, // 45 triệu VNĐ/tháng
          'area': 120.0,
          'bedrooms': 4,
          'bathrooms': 3,
          'kitchens': 1,
          'parking': 2,
          'description':
              'Nhà phố 3 tầng hiện đại, đầy đủ nội thất cao cấp, khu vực trung tâm sầm uất'
        },
        {
          'name': 'Biệt Thự Vườn Quận 2',
          'address': '456 Đường Số 9, Thảo Điền, Quận 2, TP. Hồ Chí Minh',
          'image_url': 'assets/images/house02.jpeg',
          'price': 80000000.0, // 80 triệu VNĐ/tháng
          'area': 300.0,
          'bedrooms': 5,
          'bathrooms': 4,
          'kitchens': 1,
          'parking': 3,
          'description':
              'Biệt thự sang trọng với sân vườn rộng rãi, hồ bơi riêng, khu compound an ninh'
        },
        {
          'name': 'Căn Hộ Penthouse Quận 7',
          'address': '789 Nguyễn Hữu Thọ, Phú Mỹ Hưng, Quận 7, TP. Hồ Chí Minh',
          'image_url': 'assets/images/offer01.jpeg',
          'price': 35000000.0, // 35 triệu VNĐ/tháng
          'area': 150.0,
          'bedrooms': 3,
          'bathrooms': 2,
          'kitchens': 1,
          'parking': 2,
          'description':
              'Penthouse cao cấp view sông Sài Gòn, nội thất hiện đại, tiện ích 5 sao'
        },
        {
          'name': 'Nhà Mặt Tiền Quận 3',
          'address': '321 Võ Văn Tần, Quận 3, TP. Hồ Chí Minh',
          'image_url': 'assets/images/offer02.jpeg',
          'price': 28000000.0, // 28 triệu VNĐ/tháng
          'area': 100.0,
          'bedrooms': 3,
          'bathrooms': 2,
          'kitchens': 1,
          'parking': 1,
          'description':
              'Nhà mặt tiền đường lớn, thích hợp kinh doanh hoặc làm văn phòng công ty'
        },
        {
          'name': 'Villa Biển Vũng Tàu',
          'address': '555 Trần Phú, Phường 5, TP. Vũng Tàu',
          'image_url': 'assets/images/house01.jpeg',
          'price': 50000000.0, // 50 triệu VNĐ/tháng
          'area': 250.0,
          'bedrooms': 4,
          'bathrooms': 3,
          'kitchens': 1,
          'parking': 3,
          'description':
              'Villa view biển tuyệt đẹp, khu nghỉ dưỡng cao cấp, đầy đủ tiện nghi'
        },
        {
          'name': 'Nhà Phố Thủ Đức',
          'address': '111 Võ Văn Ngân, Thủ Đức, TP. Hồ Chí Minh',
          'image_url': 'assets/images/house02.jpeg',
          'price': 18000000.0, // 18 triệu VNĐ/tháng
          'area': 80.0,
          'bedrooms': 2,
          'bathrooms': 2,
          'kitchens': 1,
          'parking': 1,
          'description':
              'Nhà mới xây, gần trường đại học, khu vực yên tĩnh, an ninh tốt'
        },
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
        print('  ✅ Đã thêm: ${house['name']}');
      }

      print('✅ Đã thêm tất cả dữ liệu mẫu');
    } catch (e) {
      print('❌ Lỗi thêm dữ liệu mẫu: $e');
      rethrow;
    }
  }

  Future<void> checkData() async {
    try {
      final conn = await connection;

      final houses = await conn.query('SELECT COUNT(*) FROM houses');
      final users = await conn.query('SELECT COUNT(*) FROM users');
      final bookings = await conn.query('SELECT COUNT(*) FROM bookings');
      final admins =
          await conn.query("SELECT COUNT(*) FROM users WHERE role = 'admin'");

      print('\n📊 Trạng thái Database:');
      print('  Nhà: ${houses.first[0]}');
      print('  Người dùng: ${users.first[0]}');
      print('  Quản trị viên: ${admins.first[0]}');
      print('  Đặt phòng: ${bookings.first[0]}');
    } catch (e) {
      print('❌ Lỗi kiểm tra dữ liệu: $e');
    }
  }
}