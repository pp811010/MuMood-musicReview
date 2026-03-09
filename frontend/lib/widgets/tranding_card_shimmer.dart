import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TrendingCardShimmer extends StatelessWidget {
  final int itemCount;
  const TrendingCardShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[850]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 100, color: Colors.grey[850]),
                  const SizedBox(height: 5),
                  Container(height: 12, width: 70, color: Colors.grey[850]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}