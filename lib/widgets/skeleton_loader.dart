import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderSkeleton(context),
          // Prayer times skeleton now part of the scrollable content
          _buildPrayerTimesSkeleton(context),
          const SizedBox(height: 10),
          _buildQuickAccessSkeleton(),
          _buildTopZakirsSkeleton(),
          const SizedBox(height: 20),
          _buildFeaturedContentSkeleton(),
          const SizedBox(height: 20),
          _buildExploreSkeleton(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.14,
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          // App bar skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmerBox(30, 30, borderRadius: 15),
                _buildShimmerBox(130, 22),
                _buildShimmerBox(30, 30, borderRadius: 15),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Calendar skeleton
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.07,
            ),
            child: Center(
              child: Container(
                width: screenWidth * 0.9,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Calendar icon placeholder
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[400]!,
                        highlightColor: Colors.grey[300]!,
                        child: Container(
                          width: 18,
                          height: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Date text placeholder
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[400]!,
                              highlightColor: Colors.grey[300]!,
                              child: Container(
                                width: 140,
                                height: 10,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[400]!,
                              highlightColor: Colors.grey[300]!,
                              child: Container(
                                width: 110,
                                height: 8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesSkeleton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: screenWidth * 0.94,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.green.shade700.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prayer times divider
            Container(
              width: double.infinity,
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade900],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            // Prayer times content
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 2,
              ), // Reduced padding
              child: SizedBox(
                height: 48, // Fixed height to prevent overflow
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < 5; i++) ...[
                      if (i > 0) _buildVerticalDividerSkeleton(),
                      _buildPrayerTimeBlockSkeleton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeBlockSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 24, height: 10, color: Colors.white),
        ),
        const SizedBox(height: 1),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 28, height: 8, color: Colors.white),
        ),
        const SizedBox(height: 1), // Add small padding at the bottom
      ],
    );
  }

  Widget _buildVerticalDividerSkeleton() {
    return Container(width: 1, height: 24, color: Colors.grey.shade200);
  }

  Widget _buildQuickAccessSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E1E1E), const Color(0xFF333333)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
              child: Row(
                children: [
                  Container(
                    height: 15,
                    width: 4,
                    color: Colors.green.shade400,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[600]!,
                    child: Container(
                      width: 80,
                      height: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildShimmerBox(
                      double.infinity,
                      double.infinity,
                      borderRadius: 12,
                      baseColor: Colors.grey[700]!,
                      highlightColor: Colors.grey[600]!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShimmerBox(
                      double.infinity,
                      double.infinity,
                      borderRadius: 12,
                      baseColor: Colors.grey[700]!,
                      highlightColor: Colors.grey[600]!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopZakirsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 20,
                width: 4,
                color: Colors.green.shade700,
                margin: const EdgeInsets.only(right: 8),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 160, height: 16, color: Colors.white),
              ),
              const Spacer(),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 50, height: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      _buildShimmerBox(75, 75, borderRadius: 37.5),
                      const SizedBox(height: 6), // Reduced from 8
                      _buildShimmerBox(70, 24, borderRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContentSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 20,
                width: 4,
                color: Colors.green.shade700,
                margin: const EdgeInsets.only(right: 8),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 140, height: 16, color: Colors.white),
              ),
              const Spacer(),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 50, height: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildShimmerBox(double.infinity, 150, borderRadius: 24),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == 0 ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      index == 0 ? Colors.green.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 20,
                width: 4,
                color: Colors.green.shade700,
                margin: const EdgeInsets.only(right: 8),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 70, height: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8), // Further reduced
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8, // Further reduced
            crossAxisSpacing: 12,
            childAspectRatio: 1.05, // Slightly wider relative to height
            children: List.generate(
              6, // Reduced to just 2 rows instead of 3
              (index) => _buildShimmerBox(
                double.infinity,
                double.infinity,
                borderRadius: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(
    double width,
    double height, {
    double borderRadius = 0,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
