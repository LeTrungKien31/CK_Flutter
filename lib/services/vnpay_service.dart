// lib/services/vnpay_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

class VNPayService {
  static final VNPayService _instance = VNPayService._internal();
  factory VNPayService() => _instance;
  VNPayService._internal();

  // Cấu hình VNPay - NHỚ dùng đúng TMNCode & HashSecret trong email
  static const String vnpTmnCode = 'Z3M71GK8'; // Mã website (TMNCode)
  static const String vnpHashSecret =
      '5SUW2HBMDQ2ZA8B7SBIAWC3SS29WOQ36'; // Chuỗi bí mật
  static const String vnpUrl =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String vnpReturnUrl = 'houserent://payment-return';

  // Tạo URL thanh toán
  Future<Map<String, dynamic>> createPaymentUrl({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? bankCode,
  }) async {
    try {
      final now = DateTime.now();
      final createDate = _formatDateTime(now);
      final txnRef = 'BOOKING_${bookingId}_${now.millisecondsSinceEpoch}';

      // VNPay yêu cầu amount * 100 (VND)
      final int vnpAmount = (amount * 100).round();

      Map<String, String> vnpParams = {
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': vnpTmnCode,
        'vnp_Amount': vnpAmount.toString(),
        'vnp_CurrCode': 'VND',
        'vnp_TxnRef': txnRef,
        'vnp_OrderInfo': orderInfo,
        'vnp_OrderType': 'other',
        'vnp_Locale': 'vn',
        'vnp_ReturnUrl': vnpReturnUrl,
        'vnp_IpAddr': '127.0.0.1',
        'vnp_CreateDate': createDate,
      };

      if (bankCode != null && bankCode.isNotEmpty) {
        vnpParams['vnp_BankCode'] = bankCode;
      }

      // Sắp xếp key theo thứ tự alphabet
      final sorted = Map.fromEntries(
        vnpParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      // ===== Chuỗi dùng để KÝ HASH (theo docs VNPay) =====
      final StringBuffer hashData = StringBuffer();
      var isFirst = true;
      sorted.forEach((key, value) {
        if (!isFirst) hashData.write('&');
        isFirst = false;
        // VNPay dùng urlencode => encode value
        hashData.write(key);
        hashData.write('=');
        hashData.write(Uri.encodeQueryComponent(value));
      });

      final secureHash = _hmacSHA512(hashData.toString(), vnpHashSecret);

      // ===== Chuỗi query dùng để tạo URL (cùng cách encode) =====
      final StringBuffer query = StringBuffer();
      isFirst = true;
      sorted.forEach((key, value) {
        if (!isFirst) query.write('&');
        isFirst = false;
        query.write(Uri.encodeQueryComponent(key));
        query.write('=');
        query.write(Uri.encodeQueryComponent(value));
      });

      final paymentUrl = '$vnpUrl?$query&vnp_SecureHash=$secureHash';

      // ignore: avoid_print
      print('✅ Payment URL created successfully');
      // ignore: avoid_print
      print('📝 TxnRef: $txnRef');
      // ignore: avoid_print
      print('💰 Amount (x100): $vnpAmount');

      return {
        'success': true,
        'paymentUrl': paymentUrl,
        'txnRef': txnRef,
      };
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error creating payment URL: $e');
      return {
        'success': false,
        'message': 'Lỗi tạo URL thanh toán: $e',
      };
    }
  }

  // Mở trình duyệt để thanh toán
  Future<bool> openPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) return false;

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error launching URL: $e');
      return false;
    }
  }

  // Xác thực callback từ VNPay
  Map<String, dynamic> verifyCallback(Map<String, String> params) {
    try {
      // ignore: avoid_print
      print('🔍 Verifying callback...');
      final vnpSecureHash = params['vnp_SecureHash'];
      if (vnpSecureHash == null) {
        return {
          'success': false,
          'message': 'Thiếu chữ ký bảo mật',
        };
      }

      // Tạo bản sao params và bỏ 2 field hash
      final verifyParams = Map<String, String>.from(params)
        ..remove('vnp_SecureHash')
        ..remove('vnp_SecureHashType');

      final sorted = Map.fromEntries(
        verifyParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      // build hashData giống hệt lúc VNPay tính
      final StringBuffer hashData = StringBuffer();
      var isFirst = true;
      sorted.forEach((key, value) {
        if (!isFirst) hashData.write('&');
        isFirst = false;
        hashData.write(key);
        hashData.write('=');
        hashData.write(Uri.encodeQueryComponent(value));
      });

      final calculatedHash = _hmacSHA512(hashData.toString(), vnpHashSecret);

      // ignore: avoid_print
      print('🔐 Hash received:   $vnpSecureHash');
      // ignore: avoid_print
      print('🔐 Hash calculated: $calculatedHash');

      if (calculatedHash != vnpSecureHash) {
        // ignore: avoid_print
        print('❌ Hash mismatch!');
        return {
          'success': false,
          'message': 'Chữ ký không hợp lệ',
        };
      }

      final responseCode = params['vnp_ResponseCode'] ?? '';
      final isSuccess = responseCode == '00';

      return {
        'success': isSuccess,
        'responseCode': responseCode,
        'txnRef': params['vnp_TxnRef'],
        'amount': params['vnp_Amount'],
        'orderInfo': params['vnp_OrderInfo'],
        'transactionNo': params['vnp_TransactionNo'],
        'bankCode': params['vnp_BankCode'],
        'payDate': params['vnp_PayDate'],
        'message': isSuccess
            ? 'Thanh toán thành công'
            : _getResponseMessage(responseCode),
      };
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error verifying callback: $e');
      return {
        'success': false,
        'message': 'Lỗi xác thực: $e',
      };
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _hmacSHA512(String data, String key) {
    final hmac = Hmac(sha512, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  String _getResponseMessage(String code) {
    switch (code) {
      case '00':
        return 'Giao dịch thành công';
      case '07':
        return 'Trừ tiền thành công. Giao dịch bị nghi ngờ';
      case '09':
        return 'Thẻ/Tài khoản chưa đăng ký InternetBanking';
      case '10':
        return 'Xác thực không đúng quá 3 lần';
      case '11':
        return 'Đã hết hạn chờ thanh toán';
      case '12':
        return 'Thẻ/Tài khoản bị khóa';
      case '13':
        return 'Nhập sai mật khẩu OTP';
      case '24':
        return 'Khách hàng hủy giao dịch';
      case '51':
        return 'Tài khoản không đủ số dư';
      case '65':
        return 'Vượt hạn mức giao dịch trong ngày';
      case '75':
        return 'Ngân hàng đang bảo trì';
      case '79':
        return 'Nhập sai mật khẩu quá số lần quy định';
      default:
        return 'Giao dịch thất bại';
    }
  }

  List<Map<String, String>> getSupportedBanks() {
    return [
      {'code': '', 'name': 'Cổng thanh toán VNPay', 'logo': 'vnpay'},
      {'code': 'VNPAYQR', 'name': 'Thanh toán qua QR Code', 'logo': 'qr'},
      {'code': 'VNBANK', 'name': 'Ngân hàng Nội địa', 'logo': 'bank'},
      {'code': 'INTCARD', 'name': 'Thẻ quốc tế', 'logo': 'card'},
    ];
  }
}
