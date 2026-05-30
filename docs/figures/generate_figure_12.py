# -*- coding: utf-8 -*-
"""Generate figure-12-api-integration.svg (Рисунок 12 — схема интеграции с REST API)."""

SVG = r'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="640" viewBox="0 0 1200 640">
  <defs>
    <linearGradient id="boxBlue" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#f4f8ff"/>
      <stop offset="100%" stop-color="#e8f0fb"/>
    </linearGradient>
    <linearGradient id="boxOrange" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#fff8f0"/>
      <stop offset="100%" stop-color="#fceee0"/>
    </linearGradient>
    <linearGradient id="boxGreen" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#f3fbf4"/>
      <stop offset="100%" stop-color="#e6f4ea"/>
    </linearGradient>
    <filter id="shadow" x="-8%" y="-8%" width="116%" height="116%">
      <feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.10"/>
    </filter>
    <marker id="arrBlue" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto">
      <path d="M0,0 L10,5 L0,10 Z" fill="#003882"/>
    </marker>
    <marker id="arrOrange" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto">
      <path d="M0,0 L10,5 L0,10 Z" fill="#c45c00"/>
    </marker>
    <marker id="arrGreen" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto">
      <path d="M0,0 L10,5 L0,10 Z" fill="#2e7d32"/>
    </marker>
  </defs>

  <rect width="1200" height="640" fill="#ffffff"/>

  <!-- Row 1: main integration flow -->
  <text x="600" y="36" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="14" font-weight="600" fill="#555">
    Основной поток данных (REST / JSON)
  </text>

  <!-- 1 UI Screen -->
  <g filter="url(#shadow)">
    <rect x="24" y="58" width="148" height="96" rx="12" fill="url(#boxBlue)" stroke="#003882" stroke-width="2"/>
    <text x="98" y="88" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#003882">Экран</text>
    <text x="98" y="108" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#003882">приложения</text>
    <text x="98" y="132" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#444">Flutter UI</text>
  </g>

  <!-- arrow 1→2 -->
  <line x1="172" y1="106" x2="208" y2="106" stroke="#003882" stroke-width="2.5" marker-end="url(#arrBlue)"/>
  <text x="190" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9" fill="#666">действие</text>

  <!-- 2 ApiClient -->
  <g filter="url(#shadow)">
    <rect x="210" y="48" width="168" height="116" rx="12" fill="url(#boxBlue)" stroke="#003882" stroke-width="2"/>
    <text x="294" y="78" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#003882">ApiClient</text>
    <text x="294" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="12" font-weight="600" fill="#003882">(Dio)</text>
    <text x="294" y="118" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">JWT в заголовке</text>
    <text x="294" y="132" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">обработка 401</text>
    <text x="294" y="146" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">GET / POST</text>
  </g>

  <!-- arrow 2→3 -->
  <line x1="378" y1="106" x2="414" y2="106" stroke="#003882" stroke-width="2.5" marker-end="url(#arrBlue)"/>
  <text x="396" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9" fill="#666">HTTPS</text>

  <!-- 3 REST API -->
  <g filter="url(#shadow)">
    <rect x="416" y="48" width="188" height="116" rx="12" fill="url(#boxOrange)" stroke="#c45c00" stroke-width="2"/>
    <text x="510" y="78" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#c45c00">REST API</text>
    <text x="510" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#c45c00">портала</text>
    <text x="510" y="118" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">college.dgu.ru/api</text>
    <text x="510" y="134" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9" fill="#444">/auth · /news · /1c/schedule · …</text>
  </g>

  <!-- arrow 3→4 return -->
  <line x1="604" y1="106" x2="640" y2="106" stroke="#c45c00" stroke-width="2.5" marker-end="url(#arrOrange)"/>
  <text x="622" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9" fill="#666">ответ</text>

  <!-- 4 JSON -->
  <g filter="url(#shadow)">
    <rect x="642" y="58" width="118" height="96" rx="12" fill="#ffffff" stroke="#c45c00" stroke-width="1.8"/>
    <text x="701" y="96" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="14" font-weight="700" fill="#c45c00">JSON</text>
    <text x="701" y="118" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">тело ответа</text>
  </g>

  <!-- arrow 4→5 -->
  <line x1="760" y1="106" x2="796" y2="106" stroke="#003882" stroke-width="2.5" marker-end="url(#arrBlue)"/>
  <text x="778" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9" fill="#666">parse</text>

  <!-- 5 Models -->
  <g filter="url(#shadow)">
    <rect x="798" y="48" width="178" height="116" rx="12" fill="url(#boxGreen)" stroke="#2e7d32" stroke-width="2"/>
    <text x="887" y="78" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#2e7d32">Dart-модели</text>
    <text x="887" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">UserModel</text>
    <text x="887" y="112" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">ScheduleLesson</text>
    <text x="887" y="126" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9.5" fill="#444">GradeEntity · …</text>
  </g>

  <!-- arrow 5→6 -->
  <line x1="976" y1="106" x2="1012" y2="106" stroke="#003882" stroke-width="2.5" marker-end="url(#arrBlue)"/>
  <text x="994" y="98" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="9" fill="#666">bind</text>

  <!-- 6 Display UI -->
  <g filter="url(#shadow)">
    <rect x="1014" y="58" width="162" height="96" rx="12" fill="url(#boxBlue)" stroke="#003882" stroke-width="2"/>
    <text x="1095" y="92" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#003882">Отображение</text>
    <text x="1095" y="112" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="700" fill="#003882">в интерфейсе</text>
    <text x="1095" y="134" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#444">виджеты Flutter</text>
  </g>

  <!-- Row 2: local storage -->
  <text x="600" y="210" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="14" font-weight="600" fill="#555">
    Локальное хранение на устройстве
  </text>

  <g filter="url(#shadow)">
    <rect x="280" y="228" width="640" height="88" rx="14" fill="#fafafa" stroke="#5b8fd9" stroke-width="2"/>
    <text x="600" y="258" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="14" font-weight="700" fill="#003882">SharedPreferences</text>
    <text x="600" y="282" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#444">TokenStorage — JWT-токен и профиль · JsonCache — кэш ответов API (ключи cache:*)</text>
    <text x="600" y="300" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#666">чтение при старте · запись после успешного ответа · очистка при выходе</text>
  </g>

  <!-- connections to storage -->
  <line x1="294" y1="164" x2="294" y2="228" stroke="#2e7d32" stroke-width="2" stroke-dasharray="5 4" marker-end="url(#arrGreen)"/>
  <text x="308" y="200" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#2e7d32">токен</text>

  <line x1="887" y1="164" x2="887" y2="228" stroke="#2e7d32" stroke-width="2" stroke-dasharray="5 4" marker-end="url(#arrGreen)"/>
  <text x="901" y="200" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#2e7d32">кэш JSON</text>

  <line x1="1095" y1="154" x2="1095" y2="228" stroke="#2e7d32" stroke-width="2" stroke-dasharray="5 4" marker-end="url(#arrGreen)"/>
  <text x="1109" y="192" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#2e7d32">offline</text>

  <!-- Row 3: example endpoints table -->
  <text x="600" y="360" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="14" font-weight="600" fill="#555">
    Примеры эндпоинтов
  </text>

  <rect x="80" y="378" width="1040" height="200" rx="12" fill="#ffffff" stroke="#dddddd" stroke-width="1.5"/>

  <!-- table header -->
  <rect x="80" y="378" width="1040" height="36" rx="12" fill="#003882"/>
  <rect x="80" y="402" width="1040" height="12" fill="#003882"/>
  <text x="120" y="402" font-family="Segoe UI, Arial, sans-serif" font-size="12" font-weight="700" fill="#ffffff">Группа</text>
  <text x="340" y="402" font-family="Segoe UI, Arial, sans-serif" font-size="12" font-weight="700" fill="#ffffff">Эндпоинт</text>
  <text x="720" y="402" font-family="Segoe UI, Arial, sans-serif" font-size="12" font-weight="700" fill="#ffffff">Назначение</text>

  <!-- rows -->
  <line x1="80" y1="414" x2="1120" y2="414" stroke="#eeeeee" stroke-width="1"/>
  <text x="120" y="436" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#333">Авторизация</text>
  <text x="340" y="436" font-family="Consolas, monospace" font-size="10.5" fill="#003882">POST /auth/login · GET /auth/me</text>
  <text x="720" y="436" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#444">вход, профиль, JWT</text>

  <line x1="80" y1="448" x2="1120" y2="448" stroke="#eeeeee" stroke-width="1"/>
  <text x="120" y="470" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#333">Учёба (1С)</text>
  <text x="340" y="470" font-family="Consolas, monospace" font-size="10.5" fill="#003882">GET /1c/schedule · /1c/sync-grades</text>
  <text x="720" y="470" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#444">расписание, оценки</text>

  <line x1="80" y1="482" x2="1120" y2="482" stroke="#eeeeee" stroke-width="1"/>
  <text x="120" y="504" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#333">Контент</text>
  <text x="340" y="504" font-family="Consolas, monospace" font-size="10.5" fill="#003882">GET /news · /mobile/events</text>
  <text x="720" y="504" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#444">новости, мероприятия</text>

  <line x1="80" y1="516" x2="1120" y2="516" stroke="#eeeeee" stroke-width="1"/>
  <text x="120" y="538" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#333">Сервисы</text>
  <text x="340" y="538" font-family="Consolas, monospace" font-size="10.5" fill="#003882">GET /mobile/assignments/my · /mobile/help</text>
  <text x="720" y="538" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#444">задания, поддержка</text>

  <line x1="80" y1="550" x2="1120" y2="550" stroke="#eeeeee" stroke-width="1"/>
  <text x="120" y="572" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#333">Служебный</text>
  <text x="340" y="572" font-family="Consolas, monospace" font-size="10.5" fill="#003882">GET /health</text>
  <text x="720" y="572" font-family="Segoe UI, Arial, sans-serif" font-size="11" fill="#444">проверка доступности API</text>

  <!-- legend -->
  <rect x="80" y="598" width="1040" height="32" rx="8" fill="#f7f7f7" stroke="#dddddd" stroke-width="1"/>
  <line x1="110" y1="614" x2="140" y2="614" stroke="#003882" stroke-width="2.5"/>
  <text x="148" y="618" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#333">запрос / ответ REST</text>
  <line x1="320" y1="614" x2="350" y2="614" stroke="#2e7d32" stroke-width="2" stroke-dasharray="5 4"/>
  <text x="358" y="618" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#333">локальное хранение</text>
  <rect x="530" y="606" width="14" height="14" fill="#fceee0" stroke="#c45c00" stroke-width="1"/>
  <text x="552" y="618" font-family="Segoe UI, Arial, sans-serif" font-size="10" fill="#333">внешний API (не объект ВКР)</text>
</svg>
'''

from pathlib import Path

out_dir = Path(__file__).parent
svg_path = out_dir / "figure-12-api-integration.svg"
svg_path.write_text(SVG, encoding="utf-8")
print(f"Wrote {svg_path}")
