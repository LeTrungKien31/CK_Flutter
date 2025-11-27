// lib/screens/payment/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_rent/services/vnpay_service.dart';
import 'package:house_rent/services/booking_service.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;
  final String orderInfo;

  const PaymentScreen({
    Key? key,
    required this.bookingId,
    required this.amount,
    required this.orderInfo,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _vnpayService = VNPayService();
  final _bookingService = BookingService();

  String? _selectedBankCode;
  bool _isProcessing = false;
  String? _paymentUrl; // Để test

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      // Tạo URL thanh toán
      final result = await _vnpayService.createPaymentUrl(
        bookingId: widget.bookingId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
        bankCode: _selectedBankCode,
      );

      if (!mounted) return;

      if (result['success']) {
        final paymentUrl = result['paymentUrl'];

        // Lưu URL để debug
        setState(() {
          _paymentUrl = paymentUrl;
        });

        print('Payment URL created: $paymentUrl');

        // Show dialog với option copy URL
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mở trình duyệt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nhấn OK để mở trình duyệt thanh toán'),
                const SizedBox(height: 15),
                const Text(
                  'Nếu không mở được, nhấn "Copy URL" và dán vào trình duyệt',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: paymentUrl));
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã copy URL vào clipboard'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Copy URL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          // Mở trình duyệt
          final opened = await _vnpayService.openPaymentUrl(paymentUrl);

          if (!mounted) return;

          if (opened) {
            print('Browser opened successfully');
            // Quay về màn hình trước
            Navigator.of(context).pop({
              'waiting': true,
              'txnRef': result['txnRef'],
            });
          } else {
            print('Failed to open browser');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Không thể mở trình duyệt. URL đã được copy vào clipboard'),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Copy lại',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paymentUrl));
                  },
                ),
              ),
            );
            // Copy URL vào clipboard
            await Clipboard.setData(ClipboardData(text: paymentUrl));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final banks = _vnpayService.getSupportedBanks();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Thông tin thanh toán
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin thanh toán',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã booking:',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '#${widget.bookingId}',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nội dung:',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Expanded(
                      child: Text(
                        widget.orderInfo,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng tiền:',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${widget.amount.toStringAsFixed(0)} VNĐ',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chọn phương thức thanh toán
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn phương thức thanh toán',
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: banks.length,
                      itemBuilder: (context, index) {
                        final bank = banks[index];
                        final isSelected = _selectedBankCode == bank['code'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: RadioListTile<String?>(
                            value: bank['code'],
                            groupValue: _selectedBankCode,
                            onChanged: (value) {
                              setState(() => _selectedBankCode = value);
                            },
                            title: Text(
                              bank['name']!,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Debug info (chỉ hiển thị khi đã tạo URL)
          if (_paymentUrl != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'URL đã tạo (nhấn để copy)',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _paymentUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã copy URL'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Nút thanh toán
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Thanh toán ngay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
