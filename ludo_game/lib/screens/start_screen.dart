import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import 'game_screen.dart';

/// The very first screen the player sees.
/// Player-count / color selection gets added in Phase 7.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ColorDotsRow(),
                SizedBox(height: 24.h),
                Text(
                  'LUDO',
                  style: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.w,
                    color: AppColors.appBarText,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Flutter Edition',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 48.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.w,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small decorative row of the 4 player colors shown above the title.
class _ColorDotsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.red,
      AppColors.green,
      AppColors.yellow,
      AppColors.blue,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors
          .map(
            (c) => Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.w),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
