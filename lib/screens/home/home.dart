import 'package:flutter/material.dart';
import 'package:house_rent/models/house.dart';
import 'package:house_rent/services/house_service.dart';
import 'package:house_rent/services/auth_service.dart';
import 'package:house_rent/widgets/custom_bottom_navigation_bar.dart';
import 'package:house_rent/widgets/recommended_house.dart';
import 'package:house_rent/widgets/custom_app_bar.dart';
import 'package:house_rent/widgets/search_input.dart';
import 'package:house_rent/widgets/welcome_text.dart';
import 'package:house_rent/widgets/categories.dart';
import 'package:house_rent/widgets/best_offer.dart';
import 'package:house_rent/screens/auth/login_screen.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _houseService = HouseService();
  final _authService = AuthService();
  List<House> _recommendedHouses = [];
  List<House> _bestOfferHouses = [];
  bool _isLoading = true;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load user info
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() => _userName = user['fullName'] ?? 'User');
    }

    // Load houses from database
    final recommended = await _houseService.getRecommendedHouses();
    final bestOffer = await _houseService.getBestOfferHouses();

    setState(() {
      _recommendedHouses =
          recommended.isNotEmpty ? recommended : House.generateRecommended();
      _bestOfferHouses =
          bestOffer.isNotEmpty ? bestOffer : House.generateBestOffer();
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: deprecated_member_use
      backgroundColor: Theme.of(context).colorScheme.background,
      // hoặc surface, surfaceVariant tùy thiết kế
      appBar: CustomAppBar(onLogout: _handleLogout),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WelcomeText(userName: _userName),
                    const SearchInput(),
                    const Categories(),
                    RecommendedHouse(houses: _recommendedHouses),
                    BestOffer(houses: _bestOfferHouses),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}
