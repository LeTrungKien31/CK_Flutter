// lib/screens/admin/admin_houses_screen.dart
import 'package:flutter/material.dart';
import 'package:house_rent/services/admin_service.dart';
import 'package:house_rent/screens/admin/add_house_screen.dart';

class AdminHousesScreen extends StatefulWidget {
  const AdminHousesScreen({Key? key}) : super(key: key);

  @override
  State<AdminHousesScreen> createState() => _AdminHousesScreenState();
}

class _AdminHousesScreenState extends State<AdminHousesScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _houses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    setState(() => _isLoading = true);
    final houses = await _adminService.getAllHousesAdmin();
    if (mounted) {
      setState(() {
        _houses = houses;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddHouse() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddHouseScreen(),
      ),
    );

    // Reload nếu thêm thành công
    if (result == true) {
      _loadHouses();
    }
  }

  Future<void> _toggleAvailability(int houseId, bool currentStatus) async {
    final result = await _adminService.toggleHouseAvailability(
      houseId,
      !currentStatus,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _loadHouses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteHouse(int houseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa nhà này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final result = await _adminService.deleteHouse(houseId);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _loadHouses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method để format price an toàn
  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    try {
      if (price is num) {
        return price.toStringAsFixed(0);
      } else if (price is String) {
        final parsedPrice = double.tryParse(price);
        return parsedPrice?.toStringAsFixed(0) ?? '0';
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quản lý nhà',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToAddHouse,
            tooltip: 'Thêm nhà mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _houses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chưa có nhà nào',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddHouse,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Thêm nhà mới',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHouses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _houses.length,
                    itemBuilder: (context, index) {
                      final house = _houses[index];
                      final isAvailable = house['isAvailable'] as bool? ?? true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: Image.asset(
                                house['imageUrl'] ??
                                    'assets/images/house01.jpeg',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.home, size: 50),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          house['name'] ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge!
                                              .copyWith(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isAvailable ? 'Còn trống' : 'Đã đặt',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    house['address'] ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  // Sử dụng helper method để format price an toàn
                                  Text(
                                    '\$${_formatPrice(house['price'])}/tháng',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge!
                                        .copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _toggleAvailability(
                                            house['id'] as int,
                                            isAvailable,
                                          ),
                                          icon: Icon(
                                            isAvailable
                                                ? Icons.close
                                                : Icons.check,
                                            size: 18,
                                          ),
                                          label: Text(
                                            isAvailable
                                                ? 'Đánh dấu đã đặt'
                                                : 'Đánh dấu trống',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        onPressed: () =>
                                            _deleteHouse(house['id'] as int),
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      // Floating Action Button để thêm nhà
      floatingActionButton: _houses.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddHouse,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}