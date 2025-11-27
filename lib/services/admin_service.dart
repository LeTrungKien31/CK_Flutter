// lib/services/admin_service.dart
import 'package:house_rent/services/database_helper.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Lấy thống kê dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final conn = await _dbHelper.connection;

      final totalUsers = await conn.query('SELECT COUNT(*) FROM users WHERE role != \'admin\'');
      final totalHouses = await conn.query('SELECT COUNT(*) FROM houses');
      final totalBookings = await conn.query('SELECT COUNT(*) FROM bookings');
      final pendingBookings = await conn.query(
        "SELECT COUNT(*) FROM bookings WHERE status = 'pending'",
      );

      return {
        'totalUsers': totalUsers.first[0] ?? 0,
        'totalHouses': totalHouses.first[0] ?? 0,
        'totalBookings': totalBookings.first[0] ?? 0,
        'pendingBookings': pendingBookings.first[0] ?? 0,
      };
    } catch (e) {
      // ignore: avoid_print
      print('Error loading dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalHouses': 0,
        'totalBookings': 0,
        'pendingBookings': 0,
      };
    }
  }

  // Lấy bookings theo status
  Future<List<Map<String, dynamic>>> getBookingsByStatus(String status) async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query(
        '''
        SELECT 
          b.id, b.check_in_date, b.check_out_date, b.total_price, b.status, b.notes, b.booking_date,
          h.name as house_name, h.address as house_address, h.image_url as house_image,
          u.full_name as user_name, u.email as user_email, u.phone as user_phone
        FROM bookings b
        JOIN houses h ON b.house_id = h.id
        JOIN users u ON b.user_id = u.id
        WHERE b.status = @status
        ORDER BY b.booking_date DESC
        ''',
        substitutionValues: {'status': status},
      );

      return results.map((row) {
        return {
          'id': row[0],
          'checkInDate': row[1],
          'checkOutDate': row[2],
          'totalPrice': row[3],
          'status': row[4],
          'notes': row[5],
          'bookingDate': row[6],
          'houseName': row[7],
          'houseAddress': row[8],
          'houseImage': row[9],
          'userName': row[10],
          'userEmail': row[11],
          'userPhone': row[12],
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading bookings: $e');
      return [];
    }
  }

  // Cập nhật status booking
  Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      final conn = await _dbHelper.connection;

      await conn.execute(
        '''
        UPDATE bookings
        SET status = @status
        WHERE id = @bookingId
        ''',
        substitutionValues: {
          'bookingId': bookingId,
          'status': status,
        },
      );

      return {
        'success': true,
        'message': 'Cập nhật trạng thái thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Lấy tất cả users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query(
        '''
        SELECT id, email, full_name, phone, address, created_at
        FROM users
        WHERE role != 'admin'
        ORDER BY created_at DESC
        ''',
      );

      return results.map((row) {
        return {
          'id': row[0],
          'email': row[1],
          'fullName': row[2],
          'phone': row[3],
          'address': row[4],
          'createdAt': row[5],
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading users: $e');
      return [];
    }
  }

  // Xóa user
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final conn = await _dbHelper.connection;

      // Xóa bookings của user trước
      await conn.execute(
        'DELETE FROM bookings WHERE user_id = @userId',
        substitutionValues: {'userId': userId},
      );

      // Xóa user
      await conn.execute(
        'DELETE FROM users WHERE id = @userId',
        substitutionValues: {'userId': userId},
      );

      return {
        'success': true,
        'message': 'Xóa người dùng thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Lấy tất cả houses
  Future<List<Map<String, dynamic>>> getAllHousesAdmin() async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query(
        '''
        SELECT id, name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description, is_available
        FROM houses
        ORDER BY created_at DESC
        ''',
      );

      return results.map((row) {
        return {
          'id': row[0],
          'name': row[1],
          'address': row[2],
          'imageUrl': row[3],
          'price': row[4],
          'area': row[5],
          'bedrooms': row[6],
          'bathrooms': row[7],
          'kitchens': row[8],
          'parking': row[9],
          'description': row[10],
          'isAvailable': row[11],
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading houses: $e');
      return [];
    }
  }

  // Xóa house
  Future<Map<String, dynamic>> deleteHouse(int houseId) async {
    try {
      final conn = await _dbHelper.connection;

      // Kiểm tra có booking nào đang active không
      final activeBookings = await conn.query(
        "SELECT COUNT(*) FROM bookings WHERE house_id = @houseId AND status IN ('pending', 'confirmed')",
        substitutionValues: {'houseId': houseId},
      );

      if ((activeBookings.first[0] as int) > 0) {
        return {
          'success': false,
          'message': 'Không thể xóa nhà có booking đang active',
        };
      }

      // Xóa bookings cũ
      await conn.execute(
        'DELETE FROM bookings WHERE house_id = @houseId',
        substitutionValues: {'houseId': houseId},
      );

      // Xóa house
      await conn.execute(
        'DELETE FROM houses WHERE id = @houseId',
        substitutionValues: {'houseId': houseId},
      );

      return {
        'success': true,
        'message': 'Xóa nhà thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Toggle house availability
  Future<Map<String, dynamic>> toggleHouseAvailability(
    int houseId,
    bool isAvailable,
  ) async {
    try {
      final conn = await _dbHelper.connection;

      await conn.execute(
        '''
        UPDATE houses
        SET is_available = @isAvailable
        WHERE id = @houseId
        ''',
        substitutionValues: {
          'houseId': houseId,
          'isAvailable': isAvailable,
        },
      );

      return {
        'success': true,
        'message': 'Cập nhật trạng thái thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }
}