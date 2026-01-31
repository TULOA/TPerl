-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if (GetLocale() == "esES" or GetLocale() == "esMX") then

	-- Thanks Hastings for translations
	TPerl_LongDescription	= "Reemplazo para los marcos de unidades, con nuevo aspecto para Jugador, Mascota, Grupo, Objetivo, Objetivo del Objetivo, Foco y Banda"

	TPERL_MINIMAP_HELP1 = "|c00FFFFFFClick izquierdo|r para Opciones (y para |c0000FF00desbloquear los marcos|r)"
	TPERL_MINIMAP_HELP2 = "|c00FFFFFFClick derecho|r para mover este icono"
	TPERL_MINIMAP_HELP3 = "\rMiembros de la Banda: |c00FFFF80%d|r\rMiembros del Grupo: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4 = "\rEres el lider del grupo/raid"
	TPERL_MINIMAP_HELP5 = "|c00FFFFFFAlt|r para ver el uso de memoria de TPerl"
	TPERL_MINIMAP_HELP6 = "|c00FFFFFF+Shift|r para ver el uso de memoria de TPerl desde el inicio"

	TPERL_MINIMENU_OPTIONS	= "Opciones"
	TPERL_MINIMENU_ASSIST	= "Mostrar el Asistente de Marco"
	TPERL_MINIMENU_CASTMON	= "Mostrar Monitor de Casteo"
	TPERL_MINIMENU_RAIDAD	= "Mostrar Admin Banda"
	TPERL_MINIMENU_ITEMCHK	= "Mostrar Comprobador Elementos"
	TPERL_MINIMENU_RAIDBUFF = "Buffs Banda"
	TPERL_MINIMENU_ROSTERTEXT="Lista Texto"
	TPERL_MINIMENU_RAIDSORT = "Orden Banda"
	TPERL_MINIMENU_RAIDSORT_GROUP = "Ordenar por Grupo"
	TPERL_MINIMENU_RAIDSORT_CLASS = "Ordenar por Clase"

	TPERL_TYPE_NOT_SPECIFIED = "No indicado"
	TPERL_TYPE_PET		= "Mascota"
	TPERL_TYPE_BOSS		= "Jefe"
	TPERL_TYPE_RAREPLUS 	= "Raro+"
	TPERL_TYPE_ELITE	= "\195\137lite"
	TPERL_TYPE_RARE		= "Raro"

	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "Caverna Santuario Serpiente"
	TPERL_LOC_ZONE_BLACK_TEMPLE = "El Templo Oscuro"
	TPERL_LOC_ZONE_HYJAL_SUMMIT = "Cima Hyjal"
	TPERL_LOC_ZONE_KARAZHAN = "Karazhan"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU = "Meseta de la Fuente del Sol"
	TPERL_LOC_ZONE_ULDUAR = "Ulduar"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "Prueba del Cruzado"
	TPERL_LOC_ZONE_ICECROWN_CITADEL = "Ciudadela de la Corona de Hielo"
	TPERL_LOC_ZONE_RUBY_SANCTUM = "El Sagrario Rubí"

	-- Status
	TPERL_LOC_DEAD		= "Muerto"
	TPERL_LOC_GHOST 	= "Fantasma"
	TPERL_LOC_FEIGNDEATH	= "Fingir muerte"
	TPERL_LOC_OFFLINE	= "Desconectado"
	TPERL_LOC_RESURRECTED	= "Resucitado"
	TPERL_LOC_SS_AVAILABLE	= "PA disponible"
	TPERL_LOC_UPDATING	= "Actualizando"
	TPERL_LOC_ACCEPTEDRES	= "Aceptado"	-- Res accepted
	TPERL_RAID_GROUP	= "Grupo %d"
	TPERL_RAID_GROUPSHORT	= "G%d"

	TPERL_LOC_NONEWATCHED	= "Ninguno mirado"

	TPERL_LOC_STATUSTIP = "Condici\195\179n Destacados: " 	-- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "Sanaci\195\179n en el Tiempo",
		AGGRO = "Agresivo",
		MISSING = "Perdiendo tus buffs de clase",
		HEAL = "Siendo sanado",
		SHIELD = "Blindado"
	}

	TPERL_OK	= "Vale"
	TPERL_CANCEL	= "Cancelar"

	TPERL_LOC_LARGENUMTAG		= "K"
	TPERL_LOC_HUGENUMTAG		= "M"
	TPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_TPERL = "TPerl enlaces de teclas"
	BINDING_NAME_TPERL_TOGGLERAID = "Mostrar ventanas de bandas"
	BINDING_NAME_TPERL_TOGGLERAIDSORT = "Mostrar orden de banda por Clase/Grupo"
	BINDING_NAME_TPERL_TOGGLERAIDPETS = "Alternar Mascotas de Banda"
	BINDING_NAME_TPERL_TOGGLEOPTIONS = "Mostrar ventana de opciones"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE = "Mostrar Ventajas/Desventajas/Nada"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE = "Mostrar Disponibles/Curables"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR = "Monitor de Teamspeak"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER = "Alternar Buscador Rango"

	TPERL_KEY_NOTICE_RAID_BUFFANY = "Mostrar ventajas/desventajas"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Mostrar s\195\179lo ventajas/desventajas disponibles/curables"
	TPERL_KEY_NOTICE_RAID_BUFFS = "Las ventajas de la banda se muestran"
	TPERL_KEY_NOTICE_RAID_DEBUFFS = "Las desventajas de la banda est\195\161n ocultas"
	TPERL_KEY_NOTICE_RAID_NOBUFFS = "No se muestran ventajas de banda"

	TPERL_DRAGHINT1	= "|c00FFFFFFClick|r para escalar ventana"
	TPERL_DRAGHINT2	= "|c00FFFFFFShift+Click|r para redimensionar ventana"

	-- Usage
	TPerlUsageNameList	= {TPerl = "N\195\186cleo", TPerl_Player = "Jugador", TPerl_PlayerPet = "Mascota", TPerl_Target = "Objetivo", TPerl_TargetTarget = "Objetivo de Objetivo", TPerl_Party = "Grupo", TPerl_PartyPet = "Mascotas Grupo", TPerl_RaidFrames = "Marcos Banda", TPerl_RaidHelper = "Ayudante Banda", TPerl_RaidAdmin = "Admin Banda", TPerl_TeamSpeak = "Monitor TS", TPerl_RaidMonitor = "Monitor Banda", TPerl_RaidPets = "Mascotas Banda", TPerl_ArcaneBar = "Barra Arcana", TPerl_PlayerBuffs = "Buffs Jugador", TPerl_GrimReaper = "Grim Reaper"}
	TPERL_USAGE_MEMMAX	= "UI Mem Max: %d"
	TPERL_USAGE_MODULES 	= "M\195\179dulos: "
	TPERL_USAGE_NEWVERSION	= "*Nueva versi\195\179n"
	TPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r est\195\161 disponible para descarga"

	TPERL_CMD_MENU		= "men\195\186"
	TPERL_CMD_OPTIONS	= "opciones"
	TPERL_CMD_LOCK		= "bloquear"
	TPERL_CMD_UNLOCK	= "desbloquear"
	TPERL_CMD_CONFIG	= "configurar"
	TPERL_CMD_LIST		= "listar"
	TPERL_CMD_DELETE	= "eliminar"
	TPERL_CMD_HELP		= "|c00FFFF80Usar: |c00FFFFFF/xperl menu | lock | unlock | config list | config delete <realm> <name>"
	TPERL_CANNOT_DELETE_CURRENT 	= "No puedes eliminar tu configuraci\195\179n actual"
	TPERL_CONFIG_DELETED		= "Eliminada configuraci\195\179n para %s/%s"
	TPERL_CANNOT_FIND_DELETE_TARGET = "No puedo encontrar configuraci\195\179n a borrar (%s/%s)"
	TPERL_CANNOT_DELETE_BADARGS 	= "Por favor dame un nombre de realm y otro de jugador"
	TPERL_CONFIG_LIST		= "Lista Configuraci\195\179n:"
	TPERL_CONFIG_CURRENT		= " (Actual)"

	TPERL_RAID_TOOLTIP_WITHBUFF	= "Con ventaja: (%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF	= "Sin ventaja: (%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s ha usado la %s que expira en %s"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED = "Se detectó una nueva versión:"
end
