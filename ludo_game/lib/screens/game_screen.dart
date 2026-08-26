import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../widgets/ludo_board.dart';

/// The main gameplay screen.
///
/// The board itself is sized with a plain [LayoutBuilder] rather than
/// ScreenUtil: it needs to be the largest possible *square* that fits
/// the actually available space (min of width/height, after the AppBar
/// and SafeArea insets), which is a live-constraint problem — not a
/// fixed design-pixel value that scales, which is what ScreenUtil's
/// .w/.h are for. ScreenUtil is used everywhere else on this screen
/// (padding, text) for consistency with the rest of the app.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        foregroundColor: AppColors.appBarText,
        title: Text(
          'Ludo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep the board perfectly square and never larger than the
              // available space, with a little breathing room on the sides.
              final double maxSize = constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight;
              final double boardSize = maxSize * 0.94;

              return Center(
                child: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: const LudoBoard(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
