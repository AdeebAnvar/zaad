import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';

class CustomLoading extends StatefulWidget {
  const CustomLoading({Key? key}) : super(key: key);

  @override
  State<CustomLoading> createState() => _CustomLoadingState();
}

class _CustomLoadingState extends State<CustomLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // repeat forever
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose(); // clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryColor,
              width: 4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor),
            ),
          ),
        ),
      ),
    );
  }
}
