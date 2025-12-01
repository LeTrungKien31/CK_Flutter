import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:house_rent/models/house.dart';
import 'package:house_rent/services/auth_service.dart';
import 'package:house_rent/services/booking_service.dart';
import 'package:house_rent/services/house_service.dart';
import 'package:house_rent/screens/payment/payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final House house;
  const BookingScreen({Key? key, required this.house}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _authService = AuthService();
  final _bookingService = BookingService();
  final _houseService = HouseService();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ---------- TIỀN & NGÀY ----------

  int _calculateDays() {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  /// DB: price lưu theo **nghìn đồng / ngày**
  /// VD: 4000  -> 4.000.000 đ / ngày
  ///     4455  -> 4.455.000 đ / ngày
  double _getDailyPriceVND() {
    final priceThousand = (widget.house.price ?? 0).toDouble();
    return priceThousand * 1000;
  }

  /// Tổng tiền = số ngày * giá/ngày (VND)
  double _calculateTotalPriceVND() {
    final days = _calculateDays();
    if (days <= 0) return 0;
    return _getDailyPriceVND() * days;
  }

  String _formatVND(double amount) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatMillionPerDay(double dailyPriceVND) {
    if (dailyPriceVND <= 0) return 'Liên hệ';
    final million = dailyPriceVND / 10000000;
    return '${million.toStringAsFixed(3)} USD / ngày';
  }

  // ---------- CHỌN NGÀY ----------

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
            _checkOutDate = null;
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  // ---------- HANDLE ĐẶT PHÒNG ----------

  Future<void> _handleBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày nhận và trả phòng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đặt phòng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Resolve house ID nếu cần
    if (widget.house.id == null) {
      final resolved = await _houseService.getHouseByName(widget.house.name);
      if (resolved != null) widget.house.id = resolved.id;
    }

    if (widget.house.id == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đặt phòng: thông tin nhà chưa hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalPriceVND = _calculateTotalPriceVND();

    // Lưu booking xuống DB
    final result = await _bookingService.createBooking(
      userId: user['userId'],
      house: widget.house,
      checkInDate: _checkInDate!,
      checkOutDate: _checkOutDate!,
      totalPrice: totalPriceVND,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final bookingId = result['bookingId'];

      final paymentMethod = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn phương thức thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Thanh toán online qua VNPay'),
                subtitle: Text(
                  _formatVND(totalPriceVND),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                onTap: () => Navigator.pop(context, 'vnpay'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.orange),
                title: const Text('Thanh toán sau'),
                subtitle: const Text('Thanh toán khi nhận phòng'),
                onTap: () => Navigator.pop(context, 'later'),
              ),
            ],
          ),
        ),
      );

      if (paymentMethod == null) return;

      if (paymentMethod == 'vnpay') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              bookingId: bookingId,
              amount: totalPriceVND, // VND thật
              orderInfo: 'Thanh toán đặt phòng ${widget.house.name}',
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thành công'),
            content: const Text(
                'Đặt phòng thành công! Bạn có thể thanh toán khi nhận phòng.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final totalPriceVND = _calculateTotalPriceVND();
    final dailyPriceVND = _getDailyPriceVND();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Đặt Phòng',
          style: TextStyle(
            color: Theme.of(context).textTheme.displayLarge!.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin nhà
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        widget.house.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.house.name,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge!
                                .copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.house.address,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatMillionPerDay(dailyPriceVND),
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge!
                                .copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Chọn ngày
              _buildDatePicker(
                label: 'Ngày nhận phòng',
                isCheckIn: true,
                date: _checkInDate,
              ),
              const SizedBox(height: 15),
              _buildDatePicker(
                label: 'Ngày trả phòng',
                isCheckIn: false,
                date: _checkOutDate,
              ),
              const SizedBox(height: 20),

              // Ghi chú
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'Nhập ghi chú của bạn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // Tổng tiền
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Số ngày:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '${_calculateDays()} ngày',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giá thuê/ngày:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          _formatVND(dailyPriceVND),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền:',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _formatVND(totalPriceVND),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Nút xác nhận
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác Nhận Đặt Phòng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required bool isCheckIn,
    required DateTime? date,
  }) {
    return GestureDetector(
      onTap: () => _selectDate(context, isCheckIn),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date == null
                        ? 'Chọn ngày'
                        : '${date.day}/${date.month}/${date.year}',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
