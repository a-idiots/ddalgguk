import 'package:flutter/material.dart';

class BadgeData {
  const BadgeData({
    required this.title,
    required this.subtitle,
    required this.iconText1,
    this.iconText2,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String iconText1;
  final String? iconText2;
  final Color color;
}

const Map<int, BadgeData> drinkingBadges = {
  0: BadgeData(
    title: '술이술술술',
    subtitle: '3일 연속 음주',
    iconText1: '연속',
    iconText2: '음주',
    color: Color(0xFFFFB3B3), // Light Pink
  ),
  1: BadgeData(
    title: '과음 1단계',
    subtitle: '상습적 주량 초과범',
    iconText1: '과음',
    iconText2: null,
    color: Color(0xFFFF8080), // Pink
  ),
  2: BadgeData(
    title: '과음 2단계',
    subtitle: '상습적 주량 초과범',
    iconText1: '과음',
    iconText2: null,
    color: Color(0xFFFF6666), // Darker Pink
  ),
  3: BadgeData(
    title: '매일알딸딸',
    subtitle: '네주량을알라',
    iconText1: '만취',
    iconText2: null,
    color: Color(0xFFE53935), // Red
  ),
  4: BadgeData(
    title: '에탄올꿀꺽',
    subtitle: '월순수알콜만500',
    iconText1: '500',
    iconText2: null,
    color: Color(0xFFE53935), // Red
  ),
  5: BadgeData(
    title: '에탄올로 위세척',
    subtitle: '월순수알콜만1000',
    iconText1: '1000',
    iconText2: null,
    color: Color(0xFFE53935), // Red
  ),
  6: BadgeData(
    title: '누적 알콜 3000',
    subtitle: '매주가 건강 염려',
    iconText1: '3000',
    iconText2: null,
    color: Color(0xFFE53935), // Red
  ),
  7: BadgeData(
    title: '누적 알콜 5000',
    subtitle: '매주가 건강 염려',
    iconText1: '5000',
    iconText2: null,
    color: Color(0xFFE53935), // Red
  ),
};

const Map<int, BadgeData> sobrietyBadges = {
  0: BadgeData(
    title: '술없는일주일',
    subtitle: '7일 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF99E6B3), // Light Green
  ),
  1: BadgeData(
    title: '술없는이주일',
    subtitle: '2주 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF66CC88), // Green
  ),
  2: BadgeData(
    title: '술없는삼주일',
    subtitle: '3주 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF33B366), // Darker Green
  ),
  3: BadgeData(
    title: '술없는한달',
    subtitle: '한달 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF33B366), // Darker Green
  ),
  4: BadgeData(
    title: '술없는두달',
    subtitle: '두달 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF33B366), // Darker Green
  ),
  5: BadgeData(
    title: '술없는세달',
    subtitle: '세달 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF33B366), // Darker Green
  ),
  6: BadgeData(
    title: '술없는반년',
    subtitle: '반년 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF33B366), // Darker Green
  ),
  7: BadgeData(
    title: '술없는1년',
    subtitle: '1년 연속 금주',
    iconText1: '연속',
    iconText2: '금주',
    color: Color(0xFF33B366), // Darker Green
  ),
};
