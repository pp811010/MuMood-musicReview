import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SongCardShimmer extends StatelessWidget {
  final int itemCount = 10;
  const SongCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[850]!,
          highlightColor: Colors.grey[700]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 14, width: 100, color: Colors.grey[850]),
              const SizedBox(height: 5),
              Container(height: 12, width: 70, color: Colors.grey[850]),
            ],
          ),
        ),
      );
  }
}