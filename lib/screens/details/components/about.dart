import 'package:flutter/material.dart';

class About extends StatelessWidget {
  final String? description;

  const About({
    Key? key,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả',
            style: textTheme.displayLarge!.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description?.isNotEmpty == true
                ? description!
                : 'Chưa có mô tả cho căn nhà này.',
            style: textTheme.bodyLarge!.copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
