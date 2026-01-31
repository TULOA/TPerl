--[[
	Localisation file
	Translated by StingerSoft
]]

if (GetLocale() == "ruRU") then
TPERL_ADMIN_TITLE	= TPerl_ShortProductName.." Рейд Админ"

TPERL_MSG_PREFIX	= "|c00C05050TPerl|r "

-- Raid Admin
TPERL_BUTTON_ADMIN_PIN		= "Закрепить Окно"
TPERL_BUTTON_ADMIN_LOCKOPEN	= "Блокировка открытого окна"
TPERL_BUTTON_ADMIN_SAVE1	= "Сохр-ть Список"
TPERL_BUTTON_ADMIN_SAVE2	= "Сохраняет текущий список с определённым именем. Если имя не заданно, будет использоваться текущее время вместо имени"
TPERL_BUTTON_ADMIN_LOAD1	= "Загр-ть Список"
TPERL_BUTTON_ADMIN_LOAD2	= "Загружает выбранный список. Любые участники рейда кто не сохранён в списке будут заменены вместо других с соответствующим классом"
TPERL_BUTTON_ADMIN_DELETE1	= "Удалить Список"
TPERL_BUTTON_ADMIN_DELETE2	= "Удалить выбранный список"
TPERL_BUTTON_ADMIN_STOPLOAD1 = "Остановить загрузку"
TPERL_BUTTON_ADMIN_STOPLOAD2 = "Прекратить процедуру загрузки списка"

TPERL_LOAD					= "Загр-ть"

TPERL_SAVED_ROSTER		    = "Сохр-ть список с названием '%s'"
TPERL_ADMIN_DIFFERENCES		= "%d отличие с текущим списком"
TPERL_NO_ROSTER_NAME_GIVEN	= "Не задано имя списка"
TPERL_NO_ROSTER_CALLED		= "Нет списка с названием '%s'"

-- Item Checker
TPERL_CHECK_TITLE			= TPerl_ShortProductName.." Предмет контроль"

TPERL_CHECK_NAME			= "Имя"

TPERL_CHECK_DROPITEMTIP1	= "Добытые вещи"
TPERL_CHECK_DROPITEMTIP2	= "Предмет может быть перетащен в фрейм и добавлен в список запрашиваемых вещей.\rВы можете использовать простую команду /raitem  и предметы будут добавлены сюда в будущем."
TPERL_CHECK_QUERY_DESC1		= "Запрос"
TPERL_CHECK_QUERY_DESC2		= "Выполнить проверку предметов (/raitem) на все выбранные предметы\rЗапрос всегда выдаст информацию о текущей прочности, устойчивости и реагентах"
TPERL_CHECK_LAST_DESC1		= "Последний"
TPERL_CHECK_LAST_DESC2		= "Пере-отметить предметы последнего поиска"
TPERL_CHECK_ALL_DESC1		= ALL
TPERL_CHECK_ALL_DESC2		= "Отметить все предметы"
TPERL_CHECK_NONE_DESC1		= NONE
TPERL_CHECK_NONE_DESC2		= "Снять отметку со всех предметов"
TPERL_CHECK_DELETE_DESC1	= DELETE
TPERL_CHECK_DELETE_DESC2	= "Навсегда удалить все отмеченные предметы из списка"
TPERL_CHECK_REPORT_DESC1	= "Сообщить"
TPERL_CHECK_REPORT_DESC2	= "Показать уведомление выбранных результатов в рейд чат"
TPERL_CHECK_REPORT_WITH_DESC1	= "С"
TPERL_CHECK_REPORT_WITH_DESC2	= "Уведомить людей с предметом (или не одетым) в рейд чат. Если сканирования снаряжения було выполнено, то результаты будут заменены."
TPERL_CHECK_REPORT_WITHOUT_DESC1= "Без"
TPERL_CHECK_REPORT_WITHOUT_DESC2= "Уведомить людей без предмета (или имеющих задействованый предмет) в рейд чат"
TPERL_CHECK_SCAN_DESC1		= "Скан"
TPERL_CHECK_SCAN_DESC2		= "Будет проверен каждый в рейде в пределах досягаемости, для просмотра выбранного снаряжения и отображения его в списке. Дальше 10ярд от рейда не попадут в проверку."
TPERL_CHECK_SCANSTOP_DESC1	= "Стоп Скан"
TPERL_CHECK_SCANSTOP_DESC2	= "Остановить сканирование снаряжения игроков для выбранного предмета"
TPERL_CHECK_REPORTPLAYER_DESC1	= "Доложить игроку"
TPERL_CHECK_REPORTPLAYER_DESC2	= "Доложить выбранным игрокам детали предмета или статус в рейд чат"

TPERL_CHECK_BROKEN		= "Сломанный"
TPERL_CHECK_REPORT_DURABILITY	= "Средняя прочность Рейда: %d%% и %d людей с общим количеством сломанных вещей %d"
TPERL_CHECK_REPORT_PDURABILITY	= "%s's Прочность: %d%% с %d сломанных вещей"
TPERL_CHECK_REPORT_RESISTS	= "Средняя устойчивость Рейда: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_PRESISTS	= "%s's Устойчивость: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_WITH		= " - с: "
TPERL_CHECK_REPORT_WITHOUT	= " - без: "
TPERL_CHECK_REPORT_WITH_EQ	= " - с (или не задействован): "
TPERL_CHECK_REPORT_WITHOUT_EQ	= " - без (или задействован): "
TPERL_CHECK_REPORT_EQUIPED	= " : одето: "
TPERL_CHECK_REPORT_NOTEQUIPED	= " : НЕ одето: "
TPERL_CHECK_REPORT_ALLEQUIPED	= "Все уже %s задействованы"
TPERL_CHECK_REPORT_ALLEQUIPEDOFF= "Все уже %s задействованы, но %d игрок(оа) в не сети"
TPERL_CHECK_REPORT_PITEM	= "%s имеет %d %s в инвентаре"
TPERL_CHECK_REPORT_PEQUIPED	= "%s уже %s задействован"
TPERL_CHECK_REPORT_PNOTEQUIPED	= "%s НЕ ИМЕЕТ %s одетым"
TPERL_CHECK_REPORT_DROPDOWN	= "Канал вывода"
TPERL_CHECK_REPORT_DROPDOWN_DESC= "Выберите канал вывода для результатов Предмет контроля"

TPERL_CHECK_REPORT_WITHSHORT	= " : %d с"
TPERL_CHECK_REPORT_WITHOUTSHORT	= " : %d без"
TPERL_CHECK_REPORT_EQUIPEDSHORT	= " : %d одето"
TPERL_CHECK_REPORT_NOTEQUIPEDSHORT	= " : %d НЕ одето"
TPERL_CHECK_REPORT_OFFLINE	= " : %d не в сети"
TPERL_CHECK_REPORT_TOTAL	= " : %d Всего предметов"
TPERL_CHECK_REPORT_NOTSCANNED	= " : %d не-проверено"

TPERL_CHECK_LASTINFO		= "Последние данные получены %sназад"

TPERL_CHECK_AVERAGE		= "Средний"
TPERL_CHECK_TOTALS		= "Всего"
TPERL_CHECK_EQUIPED		= "Одето"

TPERL_CHECK_SCAN_MISSING	= "Производится сканирование предметов игроков. (%d не просканировано)"

TPERL_REAGENTS			= {PRIEST = "Священная свеча", MAGE = "Порошок чар", DRUID = "Дикий шипокорень",
					SHAMAN = "Крест", WARLOCK = "Осколок души", PALADIN = "Символ божественности",
					ROGUE = "Воспламеняющийся порошок"}

TPERL_CHECK_REAGENTS		= "Реагенты"

-- Roster Text
TPERL_ROSTERTEXT_TITLE		= TPerl_ShortProductName.." Текст списка"
TPERL_ROSTERTEXT_GROUP		= "Группа %d"
TPERL_ROSTERTEXT_GROUP_DESC	= "Использовать имена для группы %d"
TPERL_ROSTERTEXT_SAMEZONE	= "Только одинаковые зоны"
TPERL_ROSTERTEXT_SAMEZONE_DESC	= "Включает только имена игроков которые находятся в той-же зоне что и вы"
TPERL_ROSTERTEXT_HELP		= "Нажмите Ctrl-C для копирования текста в буфер"
TPERL_ROSTERTEXT_TOTAL		= "Всего: %d"
TPERL_ROSTERTEXT_SETN		= "%d человек"
TPERL_ROSTERTEXT_SETN_DESC	= "Авто выбор группы для рейда %d человек "
TPERL_ROSTERTEXT_TOGGLE		= "Тумблер"
TPERL_ROSTERTEXT_TOGGLE_DESC	= "Переключатель выбранной группы"
TPERL_ROSTERTEXT_SORT		= "Сорт"
TPERL_ROSTERTEXT_SORT_DESC	= "Сортировать по имени вместо группа+имя"
end
