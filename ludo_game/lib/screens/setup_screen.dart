import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

/// Lets the player choose how many people are playing (2-4) and which
/// color each of them gets, before a match starts.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const List<PlayerColor> _defaultOrder = [
    PlayerColor.red,
    PlayerColor.green,
    PlayerColor.yellow,
    PlayerColor.blue,
  ];

  List<PlayerColor> _slotColors = _defaultOrder.take(4).toList();

  void _setPlayerCount(int count) {
    setState(() {
      if (count > _slotColors.length) {
        final remaining =
            PlayerColor.values.where((c) => !_slotColors.contains(c)).toList();
        _slotColors = [..._slotColors, ...remaining.take(count - _slotColors.length)];
      } else {
        _slotColors = _slotColors.sublist(0, count);
      }
    });
  }

  void _selectColorForSlot(int slotIndex, PlayerColor color) {
    setState(() {
      final existingIndex = _slotColors.indexOf(color);
      if (existingIndex != -1 && existingIndex != slotIndex) {
        // That color is already taken by another slot — swap them so
        // every slot always holds a distinct color.
        final temp = _slotColors[slotIndex];
        _slotColors[slotIndex] = color;
        _slotColors[existingIndex] = temp;
      } else {
        _slotColors[slotIndex] = color;
      }
    });
  }

  void _startMatch() {
    context.read<GameProvider>().initGame(_slotColors);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int playerCount = _slotColors.length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        foregroundColor: AppColors.appBarText,
        title: Text(
          'New Match',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Players',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [2, 3, 4].map((count) {
                  final bool selected = count == playerCount;
                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: ChoiceChip(
                      label: Text('$count'),
                      selected: selected,
                      onSelected: (_) => _setPlayerCount(count),
                      selectedColor: AppColors.red,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.appBarText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
              Text(
                'Assign colors',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Text(
                'Tap a color to give it to that player. Colors already in use swap automatically.',
                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  itemCount: playerCount,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    return _PlayerSlotRow(
                      slotIndex: index,
                      selectedColor: _slotColors[index],
                      onColorSelected: (c) => _selectColorForSlot(index, c),
                    );
                  },
                ),
              ),
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
                  onPressed: _startMatch,
                  child: Text(
                    'START MATCH',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerSlotRow extends StatelessWidget {
  final int slotIndex;
  final PlayerColor selectedColor;
  final ValueChanged<PlayerColor> onColorSelected;

  const _PlayerSlotRow({
    required this.slotIndex,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78.w,
            child: Text(
              'Player ${slotIndex + 1}',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 10.w,
              children: PlayerColor.values.map((color) {
                final bool isSelected = color == selectedColor;
                return GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: color.displayColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.white,
                        width: isSelected ? 3.w : 2.w,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.displayColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
