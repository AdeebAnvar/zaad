import 'package:flutter/material.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_loading.dart';

class CustomDialog {
  static bool _isShowing = false;
  static final ValueNotifier<String> _loadingTextNotifier = ValueNotifier('Loading...');

  static void showLoading(BuildContext context, {required String loadingText}) {
    if (_isShowing) return;
    _isShowing = true;
    _loadingTextNotifier.value = loadingText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingDialogContent(),
    );
  }

  static void updateLoadingText(String newText) {
    if (_isShowing) {
      _loadingTextNotifier.value = newText;
    }
  }

  static void hideLoading(BuildContext context) {
    if (_isShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isShowing = false;
    }
  }

  static void showResponsiveDialog(BuildContext context, Widget content, {String? title}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final screenHeight = MediaQuery.sizeOf(ctx).height;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: AppDialogLayout.insetPadding(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppDialogLayout.maxContentWidth(ctx),
              maxHeight: screenHeight * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Text(
                        title,
                        style: Theme.of(ctx).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                    content,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingDialogContent extends StatelessWidget {
  const _LoadingDialogContent();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double dialogWidth = size.width * 0.8;
    if (dialogWidth > 300) dialogWidth = 300;

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomLoading(),
            SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: CustomDialog._loadingTextNotifier,
              builder: (context, value, _) {
                return Text(
                  value,
                  style: AppStyles.getMediumTextStyle(fontSize: 12),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
