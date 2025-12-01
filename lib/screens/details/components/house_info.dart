import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:house_rent/models/house.dart';

class HouseInfo extends StatelessWidget {
  final House house;

  const HouseInfo({Key? key, required this.house}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _MenuInfo(
                imageUrl: 'assets/icons/bedroom.svg',
                content: '${house.bedrooms ?? 0} Phòng ngủ',
              ),
              _MenuInfo(
                imageUrl: 'assets/icons/bathroom.svg',
                content: '${house.bathrooms ?? 0} Phòng tắm',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MenuInfo(
                imageUrl: 'assets/icons/kitchen.svg',
                content: '${house.kitchens ?? 0} Nhà bếp',
              ),
              _MenuInfo(
                imageUrl: 'assets/icons/parking.svg',
                content: '${house.parking ?? 0} Chỗ đậu xe',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuInfo extends StatelessWidget {
  final String imageUrl;
  final String content;

  const _MenuInfo({Key? key, required this.imageUrl, required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          SvgPicture.asset(imageUrl),
          const SizedBox(width: 20),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}