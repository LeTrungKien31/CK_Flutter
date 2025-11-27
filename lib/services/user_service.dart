import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_helper.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Hash mật khẩu (giống AuthService)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Lấy thông tin chi tiết user
  Future<Map<String, dynamic>?> getUserDetails(int userId) async {
    try {
      final conn = await _dbHelper.connection;
      final result = await conn.query(
        '''
        SELECT id, email, full_name, phone, address, avatar_path, created_at
        FROM users
        WHERE id = @userId
        ''',
        substitutionValues: {'userId': userId},
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'userId': row[0],
        'email': row[1],
        'fullName': row[2],
        'phone': row[3],
        'address': row[4],
        'avatarPath': row[5],
        'createdAt': row[6],
      };
    } catch (e) {
      // ignore: avoid_print
      print('Error loading user details: $e');
      return null;
    }
  }

  // Cập nhật thông tin user
  Future<Map<String, dynamic>> updateUserInfo({
    required int userId,
    required String fullName,
    required String phone,
    String? address,
  }) async {
    try {
      final conn = await _dbHelper.connection;

      await conn.execute(
        '''
        UPDATE users
        SET full_name = @fullName, phone = @phone, address = @address
        WHERE id = @userId
        ''',
        substitutionValues: {
          'userId': userId,
          'fullName': fullName,
          'phone': phone,
          'address': address,
        },
      );

      return {
        'success': true,
        'message': 'Cập nhật thông tin thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Cập nhật avatar
  Future<Map<String, dynamic>> updateAvatar({
    required int userId,
    required String imagePath,
  }) async {
    try {
      // Lưu ảnh vào thư mục local
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_$userId${path.extension(imagePath)}';
      final savedImage = await File(imagePath).copy('${avatarDir.path}/$fileName');

      // Cập nhật path vào database
      final conn = await _dbHelper.connection;
      await conn.execute(
        '''
        UPDATE users
        SET avatar_path = @avatarPath
        WHERE id = @userId
        ''',
        substitutionValues: {
          'userId': userId,
          'avatarPath': savedImage.path,
        },
      );

      return {
        'success': true,
        'message': 'Cập nhật ảnh đại diện thành công',
        'avatarPath': savedImage.path,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Thay đổi mật khẩu
  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final conn = await _dbHelper.connection;

      // Hash mật khẩu
      final hashedCurrentPassword = _hashPassword(currentPassword);
      final hashedNewPassword = _hashPassword(newPassword);

      // Kiểm tra mật khẩu hiện tại
      final result = await conn.query(
        'SELECT id FROM users WHERE id = @userId AND password = @password',
        substitutionValues: {
          'userId': userId,
          'password': hashedCurrentPassword,
        },
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'Mật khẩu hiện tại không đúng',
        };
      }

      // Cập nhật mật khẩu mới
      await conn.execute(
        'UPDATE users SET password = @password WHERE id = @userId',
        substitutionValues: {
          'userId': userId,
          'password': hashedNewPassword,
        },
      );

      return {
        'success': true,
        'message': 'Đổi mật khẩu thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Lấy thống kê booking của user
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final conn = await _dbHelper.connection;

      final totalBookings = await conn.query(
        'SELECT COUNT(*) FROM bookings WHERE user_id = @userId',
        substitutionValues: {'userId': userId},
      );

      final activeBookings = await conn.query(
        "SELECT COUNT(*) FROM bookings WHERE user_id = @userId AND status = 'pending'",
        substitutionValues: {'userId': userId},
      );

      final completedBookings = await conn.query(
        "SELECT COUNT(*) FROM bookings WHERE user_id = @userId AND status = 'completed'",
        substitutionValues: {'userId': userId},
      );

      return {
        'totalBookings': totalBookings.first[0] ?? 0,
        'activeBookings': activeBookings.first[0] ?? 0,
        'completedBookings': completedBookings.first[0] ?? 0,
      };
    } catch (e) {
      // ignore: avoid_print
      print('Error loading user stats: $e');
      return {
        'totalBookings': 0,
        'activeBookings': 0,
        'completedBookings': 0,
      };
    }
  }
}