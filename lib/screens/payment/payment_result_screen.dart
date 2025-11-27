// lib/screens/payment/payment_result_screen.dart
import 'package:flutter/material.dart';
import 'package:house_rent/screens/home/home.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final String? txnRef;
  final String? transactionNo;
  final String? amount;

  const PaymentResultScreen({
    Key? key,
    required this.isSuccess,
    required this.message,
    this.txnRef,
    this.transactionNo,
    this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isSuccess
                      // ignore: deprecated_member_use
                      ? Colors.green.withOpacity(0.1)
                      // ignore: deprecated_member_use
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 100,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 30),

              // Tiêu đề
              Text(
                isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              // Thông báo
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Thông tin giao dịch
              if (isSuccess && txnRef != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (txnRef != null)
                        _buildInfoRow(
                          context,
                          'Mã tham chiếu:',
                          txnRef!,
                        ),
                      if (transactionNo != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          'Mã giao dịch:',
                          transactionNo!,
                        ),
                      ],
                      if (amount != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          'Số tiền:',
                          '${(int.parse(amount!) / 100).toStringAsFixed(0)} VNĐ',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const Home()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isSuccess) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const Home()),
                        (route) => false,
                      );
                      // Có thể navigate đến màn hình booking history
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    child: Text(
                      'Xem lịch sử đặt phòng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 14,
              ),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}