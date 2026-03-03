import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _textOnBanner = Color(0xFFFFFFFF);

/// Баннер на главной: контейнер с приветствием и данными студента, картинка card.svg справа снизу.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: const Color(0xFF003882),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4D003882), // #0038824D
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -3,
          ),
        ],
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Привет, студент!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.0,
                    color: _textOnBanner,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Имя Фамилия',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 1.0,
                    color: _textOnBanner,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: const [
                    _InfoChip(label: 'Группа', value: 'ИСИП-41'),
                    _InfoChip(label: 'Успеваемость', value: '4.92'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: -5,
            child: SvgPicture.asset(
              'assets/icons/card.svg',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  static const Color _chipBackground = Color(0x1AFFFFFF);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _chipBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  height: 1.0,
                  color: _textOnBanner,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.0,
                  color: _textOnBanner,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
