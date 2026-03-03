import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Заголовок главной страницы: иконка колледжа + текст «КОЛЛЕДЖ ДГУ».
class HomeHeaderTitle extends StatelessWidget {
  const HomeHeaderTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_icon.png',
          height: 38,
          width: 38,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Text(
          'Колледж ДГУ',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0.35, 0),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
