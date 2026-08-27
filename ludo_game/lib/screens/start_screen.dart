import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';
import 'setup_screen.dart';

/// The very first screen the player sees: start a new match, or resume
/// one that was left mid-way (Phase 7 persistence).
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Future<bool> _hasSavedMatch;

  @override
  void initState() {
    super.initState();
    _hasSavedMatch = context.read<GameProvider>().hasSavedMatch();
  }

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
                          builder: (_) => const SetupScreen(),
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
                FutureBuilder<bool>(
                  future: _hasSavedMatch,
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.appBarText,
                            side: const BorderSide(color: AppColors.disabled),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GameScreen(resume: true),
                              ),
                            );
                          },
                          child: Text(
                            'RESUME MATCH',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
