import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:house_rent/screens/profile/settings_screen.dart';
import 'package:house_rent/services/auth_service.dart';
import 'package:house_rent/services/user_service.dart';
import 'dart:io';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onLogout;
  
  const CustomAppBar({Key? key, this.onLogout}) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(50);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final _authService = AuthService();
  final _userService = UserService();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final userDetails = await _userService.getUserDetails(user['userId']);
      if (mounted) {
        setState(() {
          _avatarPath = userDetails?['avatarPath'];
        });
      }
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.home_outlined,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Trang chủ'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.search,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Tìm kiếm'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.favorite_border,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Yêu thích'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.bookmark_border,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Đã đặt'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _showMenu(context),
              icon: SvgPicture.asset('assets/icons/menu.svg'),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
                _loadAvatar(); // Reload avatar after returning from settings
              },
              child: CircleAvatar(
                backgroundImage: _avatarPath != null
                    ? FileImage(File(_avatarPath!))
                    : const AssetImage('assets/images/avatar.jpeg')
                        as ImageProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}