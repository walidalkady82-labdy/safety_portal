
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subTitle;

  const SectionHeader({super.key, required this.title,this.subTitle});

  @override
  Widget build(BuildContext context) {
    return 
        Column(
          children: [
            Text(title,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            if (subTitle != null) 
            Text(subTitle!,style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, letterSpacing: -0.5))
          ],
        );
        
  }
}
