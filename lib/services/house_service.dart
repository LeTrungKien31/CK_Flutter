import 'package:house_rent/models/house.dart';
import 'database_helper.dart';

class HouseService {
  static final HouseService _instance = HouseService._internal();
  factory HouseService() => _instance;
  HouseService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Lấy tất cả nhà
  Future<List<House>> getAllHouses() async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query('''
        SELECT id, name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description, is_available
        FROM houses
        WHERE is_available = true
        ORDER BY created_at DESC
      ''');

      return results.map((row) => House.fromDatabase(row)).toList();
    } catch (e) {
      print('Error loading houses: $e');
      return [];
    }
  }

  // Lấy nhà theo ID
  Future<House?> getHouseById(int id) async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query(
        '''
        SELECT id, name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description, is_available
        FROM houses
        WHERE id = @id
        ''',
        substitutionValues: {'id': id},
      );

      if (results.isEmpty) return null;
      return House.fromDatabase(results.first);
    } catch (e) {
      print('Error loading house: $e');
      return null;
    }
  }

  // Lấy nhà đề xuất
  Future<List<House>> getRecommendedHouses() async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query('''
        SELECT id, name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description, is_available
        FROM houses
        WHERE is_available = true
        ORDER BY price DESC
        LIMIT 5
      ''');

      return results.map((row) => House.fromDatabase(row)).toList();
    } catch (e) {
      print('Error loading recommended houses: $e');
      return [];
    }
  }

  // Lấy nhà ưu đãi
  Future<List<House>> getBestOfferHouses() async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query('''
        SELECT id, name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description, is_available
        FROM houses
        WHERE is_available = true
        ORDER BY price ASC
        LIMIT 5
      ''');

      return results.map((row) => House.fromDatabase(row)).toList();
    } catch (e) {
      print('Error loading best offer houses: $e');
      return [];
    }
  }

  // Tìm kiếm nhà
  Future<List<House>> searchHouses(String keyword) async {
    try {
      final conn = await _dbHelper.connection;
      final results = await conn.query(
        '''
        SELECT id, name, address, image_url, price, area, bedrooms, bathrooms, kitchens, parking, description, is_available
        FROM houses
        WHERE is_available = true
        AND (LOWER(name) LIKE LOWER(@keyword) OR LOWER(address) LIKE LOWER(@keyword))
        ORDER BY created_at DESC
        ''',
        substitutionValues: {'keyword': '%$keyword%'},
      );

      return results.map((row) => House.fromDatabase(row)).toList();
    } catch (e) {
      print('Error searching houses: $e');
      return [];
    }
  }
}