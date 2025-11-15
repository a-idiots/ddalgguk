import 'package:flutter/material.dart';

/// 음주량 입력 데이터를 관리하는 헬퍼 클래스
class DrinkInputData {
  DrinkInputData({
    required this.drinkType,
    required this.alcoholController,
    required this.amountController,
    required this.selectedUnit,
  });

  int drinkType;
  final TextEditingController alcoholController;
  final TextEditingController amountController;
  String selectedUnit;

  void dispose() {
    alcoholController.dispose();
    amountController.dispose();
  }
}
