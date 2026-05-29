import '../../core/constants/api_constants.dart';
import 'college_site_content.dart';

/// Статический контент с college.dgu.ru — офлайн и запасной вариант при ошибке сети.
abstract final class CollegeSiteFallback {
  static const _origin = 'https://college.dgu.ru';

  static CollegeSiteContent get defaultContent => CollegeSiteContent(
        heroTitle: 'Колледж ДГУ 2026',
        heroSubtitle:
            'Готовим востребованных специалистов, используя передовые IT-решения. '
            'Современный кампус, удобные онлайн-сервисы для учебы и прозрачный '
            'образовательный процесс для студентов и родителей',
        ecosystemTitle: 'Цифровая экосистема студента',
        ecosystemSubtitle:
            'Единая онлайн-среда, где весь учебный процесс студента как на ладони',
        features: const [
          CollegeFeatureCard(
            title: 'Цифровой профиль компетенций',
            body:
                'Мы оцифровываем каждый ваш успех. Участие в хакатонах, баллы за '
                'демо-экзамены и реальные проекты формируют верифицированный цифровой след, '
                'который сразу видят ведущие IT-работодатели региона.',
          ),
          CollegeFeatureCard(
            title: 'Бесшовная траектория развития',
            body:
                'Забудьте о сборе справок. Ваши академические данные автоматически и '
                'безопасно передаются в приёмную комиссию ДГУ и федеральные реестры. '
                'Прямой и прозрачный путь от абитуриента колледжа до бакалавра университета.',
          ),
          CollegeFeatureCard(
            title: 'Умный кампус 24/7',
            body:
                'Полный контроль над учебным процессом в реальном времени. Оценки, '
                'расписание, статистика посещаемости и индивидуальный учебный план '
                'всегда под рукой благодаря прямой интеграции с базами данных колледжа.',
          ),
        ],
        directionsTitle: 'Направления подготовки',
        directionsSubtitle: 'Выбирайте профессию будущего',
        directions: _directions,
        contacts: const CollegeContacts(
          address: 'г. Махачкала, ул. Дзержинского 21',
          phone: '+7 (872) 267-00-00',
          email: 'college@dgu.ru',
          vkUrl: 'https://vk.com/id797725918',
          telegramUrl: 'https://t.me/college_dgu',
          maxUrl:
              'https://max.ru/join/MP4f7lHEcrKg2-B_o-edsc6N7XXgCmTGo9WdKGbScho',
        ),
        quickLinks: [
          CollegeQuickLink(
            label: 'Подать заявление онлайн',
            url: 'https://www.gosuslugi.ru/vuzonline',
            external: true,
            primary: true,
          ),
          CollegeQuickLink(
            label: 'Узнать о специальностях',
            url: '$_origin/abiturient#directions',
          ),
          CollegeQuickLink(
            label: 'Сведения об образовательной организации',
            url:
                'https://college.dgu.ru/svedeniya/osnovnye-svedeniya/obshaya-informatsiya',
            external: true,
          ),
        ],
        fetchedAt: null,
      );

  static List<CollegeDirection> get _directions {
    final origin = ApiConstants.collegeSiteOrigin;
    return [
      _dir(
        origin,
        0,
        '10.02.05',
        'Информационная безопасность',
        'Обеспечение информационной безопасности автоматизированных систем',
        'Защита данных от кибератак, безопасность сетей и расследование цифровых инцидентов.',
        'oibas.png',
      ),
      _dir(
        origin,
        1,
        '09.02.11',
        'Разработка и управление ПО',
        'Разработка и управление программным обеспечением',
        'Создание программных продуктов и управление процессами их проектирования, реализации и развития.',
        'rupo.png',
      ),
      _dir(
        origin,
        2,
        '09.02.12',
        'Эксплуатация и сопровождение ИС',
        'Техническая эксплуатация и сопровождение информационных систем',
        'Обеспечение бесперебойной работы, обслуживания и поддержки информационных систем на всех этапах их жизненного цикла.',
        'tesis.png',
      ),
      _dir(
        origin,
        3,
        '40.02.01',
        'Юриспруденция',
        'Юрист в сфере права и судебного администрирования',
        'Назначение пенсий и пособий, консультирование граждан по вопросам соцзащиты.',
        'psa.png',
      ),
      _dir(
        origin,
        4,
        '40.02.02',
        'Правоохранительная служба',
        'Правоохранительная деятельность',
        'Охрана правопорядка, раскрытие преступлений и ведение административного надзора.',
        'pso.png',
      ),
      _dir(
        origin,
        5,
        '40.02.03',
        'Юриспруденция',
        'Юрист в сфере социального обеспечения',
        'Организация судопроизводства, ведение дел и обеспечение работы судов.',
        'pd.png',
      ),
      _dir(
        origin,
        6,
        '20.02.01',
        'Экология и природные комплексы',
        'Экологическая безопасность природных комплексов',
        'Контроль за состоянием окружающей среды и снижение вреда от промышленных выбросов.',
        'ebpk.png',
      ),
    ];
  }

  static CollegeDirection _dir(
    String origin,
    int index,
    String code,
    String shortLabel,
    String title,
    String description,
    String imageFile,
  ) {
    return CollegeDirection(
      code: code,
      shortLabel: shortLabel,
      title: title,
      description: description,
      imageUrl: '$origin/images/directions/$imageFile',
      sitePath: '$origin/abiturient?dir=$index#direction-$index',
    );
  }
}
