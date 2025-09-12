-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)
--Russian localization file translated by StingerSoft
if (GetLocale() == "ruRU") then

	TPerl_ProductName	    = "|cFFD00000X-Perl|r Фреймы Игроков"
	TPerl_Description	    = TPerl_ProductName.." от "..TPerl_Author
	TPerl_Version		    = TPerl_Description.." - "..TPerl_VersionNumber
	TPERL_LongDescription	= "Фреймы Игроков заменяются на новый вид Игроков, Питомцев, Группы, Цели, Целей Цели, Фокуса, Рейда"

	TPERL_MINIMAP_HELP1		= "|c00FFFFFFЛевый rклик|r - опции  (а также |c0000FF00перемещение фреймов|r)"
	TPERL_MINIMAP_HELP2		= "|c00FFFFFFПравый клик|r - перемещение иконки"
	TPERL_MINIMAP_HELP3		= "\rУчастники рейда: |c00FFFF80%d|r\rУчастники рейда: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4		= "\rВы лидер группы/рейда"
	TPERL_MINIMAP_HELP5		= "|c00FFFFFFAlt|r для просмотра потребления памяти X-Perl'ом"
	TPERL_MINIMAP_HELP6		= "|c00FFFFFF+Shift|r для просмотра потребления памяти X-Perl'ом после запуска"

	TPERL_MINIMENU_OPTIONS		= "Опции"
	TPERL_MINIMENU_ASSIST		= "Показ Фрейма Поддержки"
	TPERL_MINIMENU_CASTMON		= "Показ Монитора применений"
	TPERL_MINIMENU_RAIDAD		= "Показ Рейд Админа"
	TPERL_MINIMENU_ITEMCHK		= "Показ проверку вещей"
	TPERL_MINIMENU_RAIDBUFF		= "Баффы Рейда"
	TPERL_MINIMENU_ROSTERTEXT	="Список-Текст"
	TPERL_MINIMENU_RAIDSORT		= "Сортировка рейда"
	TPERL_MINIMENU_RAIDSORT_GROUP	= "Сортировать по группам"
	TPERL_MINIMENU_RAIDSORT_CLASS	= "Сортировать по классам"

	TPERL_TYPE_NOT_SPECIFIED	= "Не указанно"
	TPERL_TYPE_PET				= PET		-- "Pet"
	TPERL_TYPE_BOSS				= "Босс"
	TPERL_TYPE_RAREPLUS			= "Редкий+"
	TPERL_TYPE_ELITE			= "Элита"
	TPERL_TYPE_RARE				= "Редкий"

	-- Zones
	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "Змеиное святилище"
	TPERL_LOC_ZONE_BLACK_TEMPLE = "Черный храм"
	TPERL_LOC_ZONE_HYJAL_SUMMIT = "Вершина Хиджала"
	TPERL_LOC_ZONE_KARAZHAN = "Каражан"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU = "Плато Солнечного Колодца"
	TPERL_LOC_ZONE_NAXXRAMAS = "Наксрамас"
	TPERL_LOC_ZONE_OBSIDIAN_SANCTUM = "Обсидиановое святилище"
	TPERL_LOC_ZONE_EYE_OF_ETERNITY = "Око Вечности"
	TPERL_LOC_ZONE_ULDUAR = "Ульдуар"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "Испытание крестоносца"
	TPERL_LOC_ZONE_ICECROWN_CITADEL = "Цитадель Ледяной Короны"
	TPERL_LOC_ZONE_RUBY_SANCTUM = "Рубиновое святилище"

	-- Status
	TPERL_LOC_DEAD			= DEAD		-- "Dead"
	TPERL_LOC_GHOST			= "Дух"
	TPERL_LOC_FEIGNDEATH	= "Притворяется мертвым"
	TPERL_LOC_OFFLINE		= PLAYER_OFFLINE	-- "Офлайн"
	TPERL_LOC_RESURRECTED	= "Воскрешаемый"
	TPERL_LOC_SS_AVAILABLE	= "Камень души доступен"
	TPERL_LOC_UPDATING		= "Обновляется"
	TPERL_LOC_ACCEPTEDRES	= "Принято"	-- Res accepted
	TPERL_RAID_GROUP		= "Группа %d"
	TPERL_RAID_GROUPSHORT	= "Г%d"

	TPERL_LOC_NONEWATCHED	= "не наблюдался"

	TPERL_LOC_STATUSTIP = "Статус подсвечивания: " 	-- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "Исцеления за Время",
		AGGRO = "Аггро",
		MISSING = "Отсутствие классового' баффа",
		HEAL = "Излечен",
		SHIELD = "Защищенный"
	}

	TPERL_OK	= "OK"
	TPERL_CANCEL	= "Отмена"

	TPERL_LOC_LARGENUMTAG		= "K"
	TPERL_LOC_HUGENUMTAG		= "M"
	TPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_TPERL = 	TPERL_ProductName
	BINDING_NAME_TPERL_TOGGLERAID = "Окна рейда"
	BINDING_NAME_TPERL_TOGGLERAIDSORT = "Сорт рейда по классам/группам"
	BINDING_NAME_TPERL_TOGGLERAIDPETS = "Питомцы рейда"
	BINDING_NAME_TPERL_TOGGLEOPTIONS = "Окно опций"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE = "Баффы/Дебаффы/пусто"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE = "Примен./Лечение"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR = "Монитор Teamspeak'a"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER = "Определитель досягаемости"

	TPERL_KEY_NOTICE_RAID_BUFFANY = "Показ всех баффов/дебаффов"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Показ только читаемые/исцеляющие баффы или дебаффы"
	TPERL_KEY_NOTICE_RAID_BUFFS = "Показ баффов рейда"
	TPERL_KEY_NOTICE_RAID_DEBUFFS = "Показ дебаффов рейда"
	TPERL_KEY_NOTICE_RAID_NOBUFFS = "Не показ баффов рейда"

	TPERL_DRAGHINT1	= "|c00FFFFFFКлик|r для масштабирования окна"
	TPERL_DRAGHINT2	= "|c00FFFFFFShift+Клик|r для изменения размера окна"

-- Usage
	TPerlUsageNameList	= {TPerl = "Основной", 	TPERL_Player = "Игрок", 	TPERL_PlayerPet = "Питомец", 	TPERL_Target = "Цель", 	TPERL_TargetTarget = "Цель цели", 	TPERL_Party = "Группа", 	TPERL_PartyPet = "Питомцы группы", 	TPERL_RaidFrames = "Фреймы рейда", 	TPERL_RaidHelper = "Помощник рейда", 	TPERL_RaidAdmin = "Рейд-админ", 	TPERL_TeamSpeak = "Монитор TS", 	TPERL_RaidMonitor = "Рейд-монитор", 	TPERL_RaidPets = "Питомцы рейда", 	TPERL_ArcaneBar = "Индикатор заклинаний", 	TPERL_PlayerBuffs = "Баффы игрока", 	TPERL_GrimReaper = "Grim Reaper"}
	TPERL_USAGE_MEMMAX	= "UI Макс Пам: %d"
	TPERL_USAGE_MODULES = "Модули: "
	TPERL_USAGE_NEWVERSION	= "*Новейшая версия"
	TPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r доступна для скачивания"

	TPERL_CMD_HELP	= "|c00FFFF80Используйте: |c00FFFFFF/xperl menu | lock | unlock | config list | config delete <сервер> <имя>"
	TPERL_CANNOT_DELETE_CURRENT = "Невозможно удалить ваши текущие настройки"
	TPERL_CONFIG_DELETED	= "Настройки для %s/%s удалены"
	TPERL_CANNOT_FIND_DELETE_TARGET = "Нет настроек для удаления (%s/%s)"
	TPERL_CANNOT_DELETE_BADARGS = "Введите реалм и ник игрока"
	TPERL_CONFIG_LIST	= "Список настроек:"
	TPERL_CONFIG_CURRENT	= " (текущий)"

	TPERL_RAID_TOOLTIP_WITHBUFF		= "С баффом: (%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF	= "Без баффа: (%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s'а %s заканчивается через %s"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED = "Обнаружена новая версия:"
end
