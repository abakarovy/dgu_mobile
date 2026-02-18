import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../shared/widgets/app_header.dart';
import '../widgets/home_header_title.dart';
import '../widgets/home_hero_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _iconCaptionCard() {

    return Expanded(child:
      ElevatedButton(
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsetsGeometry.all(20)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(15)))
        ),
        onPressed: () {
          
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsetsGeometry.all(10),
              // color: ,
              child: SvgPicture.asset("assets/icons/schedule_icon.svg", width: 24, height: 24,),
            ),
            Text("Расписание", style: TextStyle(fontSize: 16),),
            Text("3 пары сегодня", style: TextStyle(fontSize: 10,),)

          ],
        ),
      )
    );
  }
  Widget _scheduleAndTasksSection() {

    return Row(
      children: [

        _iconCaptionCard(),
        _iconCaptionCard()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        headerTitle: HomeHeaderTitle()
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeHeroBanner(),
            _scheduleAndTasksSection()
          ],
        ),
      ),
    );
  }
}
