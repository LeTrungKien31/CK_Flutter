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

      // Thêm user mới với role mặc định là 'user'
      final hashedPassword = _hashPassword(password);
      final result = await conn.query(
        '''
        INSERT INTO users (email, password, full_name, phone, role)
        VALUES (@email, @password, @fullName, @phone, 'user')
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

  // Đăng nhập user thường
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final conn = await _dbHelper.connection;
      final hashedPassword = _hashPassword(password);

      final result = await conn.query(
        '''
        SELECT id, email, full_name, phone, role
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
      final role = user[4] as String? ?? 'user';

      // Chỉ cho phép user thường đăng nhập ở đây
      if (role == 'admin') {
        return {
          'success': false,
          'message': 'Vui lòng sử dụng trang đăng nhập admin',
        };
      }

      // Lưu thông tin đăng nhập
      await _saveLoginInfo(userId, userEmail, fullName ?? '', phone ?? '', role);

      return {
        'success': true,
        'message': 'Đăng nhập thành công',
        'userId': userId,
        'email': userEmail,
        'fullName': fullName,
        'phone': phone,
        'role': role,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Đăng nhập admin
  Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final conn = await _dbHelper.connection;
      final hashedPassword = _hashPassword(password);

      final result = await conn.query(
        '''
        SELECT id, email, full_name, phone, role
        FROM users
        WHERE email = @email AND password = @password AND role = 'admin'
        ''',
        substitutionValues: {
          'email': email,
          'password': hashedPassword,
        },
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'Email hoặc mật khẩu admin không đúng',
        };
      }

      final user = result.first;
      final userId = user[0] as int;
      final userEmail = user[1] as String;
      final fullName = user[2] as String?;
      final phone = user[3] as String?;
      final role = user[4] as String;

      // Lưu thông tin đăng nhập
      await _saveLoginInfo(userId, userEmail, fullName ?? '', phone ?? '', role);

      return {
        'success': true,
        'message': 'Đăng nhập admin thành công',
        'userId': userId,
        'email': userEmail,
        'fullName': fullName,
        'phone': phone,
        'role': role,
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
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
    await prefs.setString('phone', phone);
    await prefs.setString('role', role);
    await prefs.setBool('isLoggedIn', true);
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Kiểm tra có phải admin không
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'user';
    return role == 'admin';
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
      'role': prefs.getString('role') ?? 'user',
    };
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}