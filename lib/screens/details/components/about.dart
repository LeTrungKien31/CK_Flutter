import 'package:flutter/material.dart';

class About extends StatelessWidget {
  final String? description;
  
  const About({Key? key, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            description ?? 'Lorem ipsum dolor sit amet consectetur adipisicing elit. Dignissimos exercitationem ut cupiditate...',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 14,
                ),
          )
        ],
      ),
    );
  }
}