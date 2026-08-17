import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ddalgguk/shared/widgets/pro_plan_popup.dart';

// 결제 팝업에서 첫 페이지로 보여줄 기능 인덱스 — `custom_drinks.png` (index 1).
// 목록은 pro_plan_popup.dart의 `_featureImages`와 동일 순서.
const _kPaywallInitialFeatureIndex = 1;

const _kV2PopupShownKey = 'v2_welcome_popup_shown';

class V2WelcomePopup extends StatelessWidget {
  const V2WelcomePopup({super.key});

  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kV2PopupShownKey) ?? false) {
      return;
    }
    await prefs.setBool(_kV2PopupShownKey, true);
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => const V2WelcomePopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 50),
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).pop();
              showProPlanPopup(context, _kPaywallInitialFeatureIndex);
            },
            child: Image.asset(
              'assets/imgs/popup/alert_popup.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(width: 56, height: 56),
            ),
          ),
        ],
      ),
    );
  }
}
