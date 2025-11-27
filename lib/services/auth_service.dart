import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Hash mật khẩu
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Public wrapper để hash mật khẩu (sử dụng từ các service khác)
  String hashPassword(String password) => _hashPassword(password);

  // Đăng ký
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final conn = await _dbHelper.connection;

      // Kiểm tra email đã tồn tại
      final existing = await conn.query(
        'SELECT id FROM users WHERE email = @email',
        substitutionValues: {'email': email},
      );

      if (existing.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email đã được sử dụng',
        };
      }

      // Thêm user mới
      final hashedPassword = _hashPassword(password);
      final result = await conn.query(
        '''
        INSERT INTO users (email, password, full_name, phone)
        VALUES (@email, @password, @fullName, @phone)
        RETURNING id
        ''',
        substitutionValues: {
          'email': email,
          'password': hashedPassword,
          'fullName': fullName,
          'phone': phone,
        },
      );

      final userId = result.first[0] as int;

      return {
        'success': true,
        'message': 'Đăng ký thành công',
        'userId': userId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final conn = await _dbHelper.connection;
      final hashedPassword = _hashPassword(password);

      final result = await conn.query(
        '''
        SELECT id, email, full_name, phone
        FROM users
        WHERE email = @email AND password = @password
        ''',
        substitutionValues: {
          'email': email,
          'password': hashedPassword,
        },
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'Email hoặc mật khẩu không đúng',
        };
      }

      final user = result.first;
      final userId = user[0] as int;
      final userEmail = user[1] as String;
      final fullName = user[2] as String?;
      final phone = user[3] as String?;

      // Lưu thông tin đăng nhập
      await _saveLoginInfo(userId, userEmail, fullName ?? '', phone ?? '');

      return {
        'success': true,
        'message': 'Đăng nhập thành công',
        'userId': userId,
        'email': userEmail,
        'fullName': fullName,
        'phone': phone,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Lưu thông tin đăng nhập
  Future<void> _saveLoginInfo(
    int userId,
    String email,
    String fullName,
    String phone,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
    await prefs.setString('phone', phone);
    await prefs.setBool('isLoggedIn', true);
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) return null;

    return {
      'userId': prefs.getInt('userId'),
      'email': prefs.getString('email'),
      'fullName': prefs.getString('fullName'),
      'phone': prefs.getString('phone'),
    };
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
