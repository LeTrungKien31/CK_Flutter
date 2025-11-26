import 'database_helper.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Tạo booking mới
  Future<Map<String, dynamic>> createBooking({
    required int userId,
    required int houseId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required double totalPrice,
    String? notes,
  }) async {
    try {
      final conn = await _dbHelper.connection;

      // Kiểm tra phòng còn trống
      final houseCheck = await conn.query(
        'SELECT is_available FROM houses WHERE id = @houseId',
        substitutionValues: {'houseId': houseId},
      );

      if (houseCheck.isEmpty) {
        return {
          'success': false,
          'message': 'Phòng không tồn tại',
        };
      }

      if (!(houseCheck.first[0] as bool)) {
        return {
          'success': false,
          'message': 'Phòng đã được đặt',
        };
      }

      // Kiểm tra trùng lịch
      final conflictCheck = await conn.query(
        '''
        SELECT id FROM bookings
        WHERE house_id = @houseId
        AND status NOT IN ('cancelled', 'rejected')
        AND (
          (check_in_date <= @checkOut AND check_out_date >= @checkIn)
        )
        ''',
        substitutionValues: {
          'houseId': houseId,
          'checkIn': checkInDate.toIso8601String(),
          'checkOut': checkOutDate.toIso8601String(),
        },
      );

      if (conflictCheck.isNotEmpty) {
        return {
          'success': false,
          'message': 'Phòng đã được đặt trong khoảng thời gian này',
        };
      }

      // Tạo booking
      final result = await conn.query(
        '''
        INSERT INTO bookings (user_id, house_id, check_in_date, check_out_date, total_price, notes, status)
        VALUES (@userId, @houseId, @checkIn, @checkOut, @totalPrice, @notes, 'pending')
        RETURNING id
        ''',
        substitutionValues: {
          'userId': userId,
          'houseId': houseId,
          'checkIn': checkInDate.toIso8601String(),
          'checkOut': checkOutDate.toIso8601String(),
          'totalPrice': totalPrice,
          'notes': notes,
        },
      );

      final bookingId = result.first[0] as int;

      return {
        'success': true,
        'message': 'Đặt phòng thành công',
        'bookingId': bookingId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }

  // Lấy danh sách booking của user
  Future<List<Map<String, dynamic>>> getUserBookings(int userId) async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query(
        '''
        SELECT 
          b.id, b.check_in_date, b.check_out_date, b.total_price, b.status, b.notes, b.booking_date,
          h.name as house_name, h.address as house_address, h.image_url as house_image
        FROM bookings b
        JOIN houses h ON b.house_id = h.id
        WHERE b.user_id = @userId
        ORDER BY b.booking_date DESC
        ''',
        substitutionValues: {'userId': userId},
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
        };
      }).toList();
    } catch (e) {
      print('Error loading bookings: $e');
      return [];
    }
  }

  // Hủy booking
  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final conn = await _dbHelper.connection;

      await conn.execute(
        '''
        UPDATE bookings
        SET status = 'cancelled'
        WHERE id = @bookingId
        ''',
        substitutionValues: {'bookingId': bookingId},
      );

      return {
        'success': true,
        'message': 'Hủy đặt phòng thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }
}