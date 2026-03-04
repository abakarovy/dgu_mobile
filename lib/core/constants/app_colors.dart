import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primaryBlue = Color(0xFF003882);
  static const Color secondaryBlue = Color(0xFF1A4B8E);

  static const Color lightBlue = Color(0xFF2563EB);
  static const Color backgroundBlue = Color(0xFFEFF6FF);

  static const Color primaryGreen = Color(0xFF059669);
  static const Color backgroundGreen = Color(0xFFECFDF5);
  static const Color lightGreen = Color(0xFF10B981);

  static const Color surfaceLight = Color(0xFFF8FAFC);

  static const Color caption = Color(0xFF94A3B8);
  static const Color textPrimary = Color(0xFF1E293B); // основной текст по макету
  /// Цвет подзаголовка в настройках уведомлений (описание).
  static const Color notificationSubtitle = Color(0xFF64748B);
  static const Color grey = Color(0xFF475569);
  static const Color lightGrey = Color(0xFFCBD5E1);
  static const Color backgroundSecondary = (Color(0xFFF1F5F9));

  /// Цвета для контейнера оценки: 5 — зелёный, 4 — янтарный, 3 — оранжевый, 2/1 — красный.
  static const Color grade5Text = Color(0xFF10B981);
  static const Color grade5Bg = Color(0xFFECFDF5);
  static const Color grade4Text = Color(0xFFF59E0B);
  static const Color grade4Bg = Color(0xFFFFF7ED);
  static const Color grade3Text = Color(0xFFD97706);
  static const Color grade3Bg = Color(0xFFFFFBEB);
  static const Color grade2Text = Color(0xFFEF4444);
  static const Color grade2Bg = Color(0xFFFEF2F2);
  static const Color gradeDefaultText = Color(0xFF1E293B);
  static const Color gradeDefaultBg = Color(0xFFF1F5F9);

  static const Color onDark = Colors.white;

  /// Баннер профиля / герой: текст на синем фоне.
  static const Color textOnBanner = Color(0xFFFFFFFF);
  /// Полупрозрачный фон чипов на баннере.
  static const Color chipBackgroundOnBanner = Color(0x1AFFFFFF);
  /// Стрелка вправо в списках (профиль и т.д.).
  static const Color chevronRight = Color(0xFFCBD5E1);

  /// Переключатель уведомлений: активный трек.
  static const Color notificationSwitchActive = Color(0xFF003B73);
  /// Переключатель уведомлений: неактивный трек (выключен).
  static const Color notificationSwitchInactive = Color(0xFFCBD5E1);

  /// Фон контейнера иконки в баннере поддержки (белый 20%).
  static const Color supportBannerIconBoxBg = Color(0x33FFFFFF);
  /// Фон контейнера иконки в строках контактов (Поддержка).
  static const Color supportContactIconBg = Color(0xFFF0F4F8);
  /// Цвет названия (телефон, email, сайт) в поддержке.
  static const Color supportContactTitle = Color(0xFF003B73);
  /// Иконка телефона (горячая линия).
  static const Color supportTelIcon = Color(0xFF2B7FFF);
  /// Фон контейнера иконки телефона.
  static const Color supportTelIconBg = Color(0xFFE8F0FF);
  /// Иконка почты.
  static const Color supportMailIcon = Color(0xFF615FFF);
  /// Фон контейнера иконки почты.
  static const Color supportMailIconBg = Color(0xFFEDECFF);
  /// Иконка сайта.
  static const Color supportInternetIcon = Color(0xFF00BC7D);
  /// Фон контейнера иконки сайта.
  static const Color supportInternetIconBg = Color(0xFFE0F5EE);

  static Color onDarkMuted(double opacity) => Colors.white.withValues(alpha: opacity);

  static Color onDarkSurface(double opacity) => Colors.white.withValues(alpha: opacity);

  /// Задания: цвет чипа предмета и текст срока.
  static const Color taskChipText = Color(0xFF003B73);
  static const Color taskDeadline = Color(0xFFFF6900);

  /// Заголовок новости на экране детали.
  static const Color newsDetailTitle = Color(0xFF003B73);
  /// Цитата/курсив в тексте новости.
  static const Color newsDetailQuote = Color(0xFF1C398E);
}
