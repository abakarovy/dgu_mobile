import 'package:flutter/material.dart';

/// Отступы, размеры и радиусы UI по всему приложению.
abstract final class AppUi {
  AppUi._();

  // --- Отступы экрана и контента ---
  static const double screenPaddingH = 24;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(24);
  static const double contentPaddingH = 20;
  static const double contentPaddingV = 16;

  // --- Расстояния между элементами ---
  static const double spacingXs = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXl = 24;
  static const double spacingAfterBanner = 22;
  static const double spacingAfterButtons = 24;
  static const double spacingBetweenCards = 16;
  static const double spacingBetweenNews = 24;

  // --- Радиусы ---
  static const double radiusS = 10;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXl = 24;
  static const double avatarRadius = 40;
  static const double statCardRadius = 16;

  // --- Главная (home) ---
  static const double homeCardHeight = 122;
  static const EdgeInsets homeCardPadding = EdgeInsets.all(17);

  // --- Профиль ---
  static const double avatarSize = 128;
  static const double avatarBorderWidth = 4;
  static const double profileEditButtonSize = 36;
  static const double statCardLabelHeight = 30;

  // --- Новости ---
  static const double newsImageHeight = 160;
  static const double newsContentPaddingH = 20;
  static const double newsCardRadius = 24;

  // --- Профиль: строки-кнопки ---
  static const double profileRowIconSize = 24;
  static const double profileRowIconPadding = 12;
  static const double profileRowIconRadius = 12;

  // --- Shell / AppBar ---
  static const double shellMinWidthForTitle = 240;
  static const double appBarIconSize = 38;
  static const double appBarNotifiSize = 20;

  // --- Уведомления: переключатель ---
  static const double notificationSwitchWidth = 48;
  static const double notificationSwitchHeight = 24;
  static const double notificationSwitchThumbSize = 16;
  static const double notificationSwitchPadding = 4;
  static const double notificationSwitchRadius = 12; // height/2 для полного скругления
}
