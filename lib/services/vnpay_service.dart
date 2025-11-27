// lib/services/vnpay_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

class VNPayService {
  static final VNPayService _instance = VNPayService._internal();
  factory VNPayService() => _instance;
  VNPayService._internal();

  // Cấu hình VNPay - THAY ĐỔI THEO THÔNG TIN CỦA BẠN
  static const String vnpTmnCode = 'Z3M71GK8'; // Mã website
  static const String vnpHashSecret = '5SUW2HBMDQ2ZA8B7SBIAWC3SS29WOQ36'; // Chuỗi bí mật
  static const String vnpUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String vnpReturnUrl = 'houserent://payment-return';

  // Tạo URL thanh toán
  Future<Map<String, dynamic>> createPaymentUrl({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? bankCode,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final String createDate = _formatDateTime(now);
      final String txnRef = 'BOOKING_${bookingId}_${now.millisecondsSinceEpoch}';
      
      // Số tiền phải là số nguyên (VNĐ)
      final int vnpAmount = (amount * 100).toInt();

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

      final sortedParams = Map.fromEntries(
        vnpParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );

      final queryString = sortedParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final secureHash = _hmacSHA512(queryString, vnpHashSecret);
      final paymentUrl = '$vnpUrl?$queryString&vnp_SecureHash=$secureHash';

      return {
        'success': true,
        'paymentUrl': paymentUrl,
        'txnRef': txnRef,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi tạo URL thanh toán: ${e.toString()}',
      };
    }
  }

  // Mở trình duyệt để thanh toán - IMPROVED VERSION
  Future<bool> openPaymentUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      // Thử nhiều mode khác nhau
      // 1. Thử mở external application trước (browser riêng)
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        return true;
      }

      // 2. Nếu không được, thử platformDefault
      launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      
      if (launched) {
        return true;
      }

      // 3. Cuối cùng thử externalNonBrowserApplication
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      
      return launched;
    } catch (e) {
      // ignore: avoid_print
      print('Error launching URL: $e');
      return false;
    }
  }

  // Xác thực callback từ VNPay
  Map<String, dynamic> verifyCallback(Map<String, String> params) {
    try {
      final String? vnpSecureHash = params['vnp_SecureHash'];
      if (vnpSecureHash == null) {
        return {
          'success': false,
          'message': 'Thiếu chữ ký bảo mật',
        };
      }

      final paramsToVerify = Map<String, String>.from(params);
      paramsToVerify.remove('vnp_SecureHash');
      paramsToVerify.remove('vnp_SecureHashType');

      final sortedParams = Map.fromEntries(
        paramsToVerify.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );

      final queryString = sortedParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final calculatedHash = _hmacSHA512(queryString, vnpHashSecret);

      if (calculatedHash != vnpSecureHash) {
        return {
          'success': false,
          'message': 'Chữ ký không hợp lệ',
        };
      }

      final String responseCode = params['vnp_ResponseCode'] ?? '';
      final bool isSuccess = responseCode == '00';

      return {
        'success': isSuccess,
        'responseCode': responseCode,
        'txnRef': params['vnp_TxnRef'],
        'amount': params['vnp_Amount'],
        'orderInfo': params['vnp_OrderInfo'],
        'transactionNo': params['vnp_TransactionNo'],
        'bankCode': params['vnp_BankCode'],
        'payDate': params['vnp_PayDate'],
        'message': isSuccess ? 'Thanh toán thành công' : _getResponseMessage(responseCode),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi xác thực: ${e.toString()}',
      };
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
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
        return 'Xác thực thông tin không đúng quá 3 lần';
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
        return 'Vượt quá hạn mức giao dịch trong ngày';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì';
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