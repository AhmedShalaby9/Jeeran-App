import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PropertiesShimmer extends StatelessWidget {
  const PropertiesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
