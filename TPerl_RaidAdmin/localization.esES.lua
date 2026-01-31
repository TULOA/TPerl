--[[
	Localisation file
	Translation by Hastings
]]

if (GetLocale() == "esES") or (GetLocale() == "esMX") then
TPERL_ADMIN_TITLE	= "TPerl Administración de banda"

TPERL_MSG_PREFIX	= "|c00C05050TPerl|r "

-- Raid Admin
TPERL_BUTTON_ADMIN_PIN		= "Clavar ventana"
TPERL_BUTTON_ADMIN_LOCKOPEN	= "Bloquear ventana abierta"
TPERL_BUTTON_ADMIN_SAVE1	= "Guardar plantilla"
TPERL_BUTTON_ADMIN_SAVE2	= "Guarda el diseño de la plantilla actual con el nombre especificado. Si no se indica ninguno, se utilizará la hora actual"
TPERL_BUTTON_ADMIN_LOAD1	= "Cargar plantilla"
TPERL_BUTTON_ADMIN_LOAD2	= "Cargar la plantilla seleccionada. Cualquier miembro de la banda, que estuviera en la plantilla, y no esté ahora, será reemplazado por un miembro de la misma clase que no esté guardado en la plantilla"
TPERL_BUTTON_ADMIN_DELETE1	= "Borrar plantilla"
TPERL_BUTTON_ADMIN_DELETE2	= "Borrar la plantilla seleccionada"
TPERL_BUTTON_ADMIN_STOPLOAD1	= "Detener carga"
TPERL_BUTTON_ADMIN_STOPLOAD2	= "Aborta el proceso de carga de la plantilla"

TPERL_LOAD			= "Cargar"

TPERL_SAVED_ROSTER		= "Plantilla guardada llamada '%s'"
TPERL_ADMIN_DIFFERENCES		= "%d diferencias con la plantilla actual"
TPERL_NO_ROSTER_NAME_GIVEN	= "No se ha dado nombre para la plantilla"
TPERL_NO_ROSTER_CALLED		= "No hay ninguna plantilla guardad con el nombre '%s'"

-- Item Checker
TPERL_CHECK_TITLE		= "TPerl Comprobador de objetos"

TPERL_CHECK_NAME		= "Nombre"

TPERL_CHECK_DROPITEMTIP1	= "Arrastrar objetos"
TPERL_CHECK_DROPITEMTIP2	= "Los objetos pueden ser arrastrados a este marco para añadirlos a la lista de objetos a comprobar.\rTambién puede usar el comando /raitem normalmente y los objetos se añadirán aquí y se usarán en el futuro."
TPERL_CHECK_QUERY_DESC1		= "Comprobar"
TPERL_CHECK_QUERY_DESC2		= "Ejecuta la comprobación de objetos (/raitem) en todos los objetos seleccionados\rLa comprobación siempre obtiene la durabilidad actual, resistencia e información de ingredientes"
TPERL_CHECK_LAST_DESC1		= "Último"
TPERL_CHECK_LAST_DESC2		= "Re-marcar los objetos de la última búsqueda"
TPERL_CHECK_ALL_DESC1		= ALL
TPERL_CHECK_ALL_DESC2		= "Marcar todos los objetos"
TPERL_CHECK_NONE_DESC1		= NONE
TPERL_CHECK_NONE_DESC2		= "Desmarcar todos los objetos"
TPERL_CHECK_DELETE_DESC1	= DELETE
TPERL_CHECK_DELETE_DESC2	= "Eliminar permanentemente todos los objetos seleccionados de la lista"
TPERL_CHECK_REPORT_DESC1	= "Reporte"
TPERL_CHECK_REPORT_DESC2	= "Mostrar reporte de los resultados seleccionados en el chat de banda"
TPERL_CHECK_REPORT_WITH_DESC1	= "Con"
TPERL_CHECK_REPORT_WITH_DESC2	= "Reportar gente con el objeto (o que no lo tengan equipado) al chat de banda. Si se ha hecho un escaneo de equipo, se mostrarán estos resultados en su lugar."
TPERL_CHECK_REPORT_WITHOUT_DESC1= "Sin"
TPERL_CHECK_REPORT_WITHOUT_DESC2= "Reportar gente sin el objeto (o que lo tengan equipado) al chat de banda."
TPERL_CHECK_SCAN_DESC1		= "Escanear"
TPERL_CHECK_SCAN_DESC2		= "Comprobará a todos en el rango de inspección, para ver si llevan el objeto seleccionado equipado, e indicarlo en la lista de jugadores. Moverse más cerca (10 metros) de la gente fuera de rango hasta que toda la banda haya sido comprobada."
TPERL_CHECK_SCANSTOP_DESC1	= "Detener escaneo"
TPERL_CHECK_SCANSTOP_DESC2	= "Detener el escaneo del equipo de los jugadores para el objeto seleccionado"
TPERL_CHECK_REPORTPLAYER_DESC1	= "Reportar jugador"
TPERL_CHECK_REPORTPLAYER_DESC2	= "Reportar detalles de los jugadores seleccionados sobre este objeto o estado al chat de banda"

TPERL_CHECK_BROKEN		= "Rotos"
TPERL_CHECK_REPORT_DURABILITY	= "Durabilidad media de la banda: %d%% y %d personas con un total de de %d objetos rotos"
TPERL_CHECK_REPORT_PDURABILITY	= "Durabilidad de %s: %d%% con %d objetos rotos"
TPERL_CHECK_REPORT_RESISTS	= "Resistencias medias de la banda: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_PRESISTS	= "Resistencias de %s: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_WITH		= " - con: "
TPERL_CHECK_REPORT_WITHOUT	= " - sin: "
TPERL_CHECK_REPORT_WITH_EQ	= " - con (o no equipado): "
TPERL_CHECK_REPORT_WITHOUT_EQ	= " - sin (o equipado): "
TPERL_CHECK_REPORT_EQUIPED	= " : equipado: "
TPERL_CHECK_REPORT_NOTEQUIPED	= " : NO equipado: "
TPERL_CHECK_REPORT_ALLEQUIPED	= "Todos tienen %s equipado/a"
TPERL_CHECK_REPORT_ALLEQUIPEDOFF= "Todos tienen %s equipado/a, pero %d miembro(s) está(n) desconectado(s)"
TPERL_CHECK_REPORT_PITEM	= "%s tiene %d %s en el inventario"
TPERL_CHECK_REPORT_PEQUIPED	= "%s tiene %s equipado/a"
TPERL_CHECK_REPORT_PNOTEQUIPED	= "%s NO tiene %s equipado/a"
TPERL_CHECK_REPORT_DROPDOWN	= "Canal de salida"
TPERL_CHECK_REPORT_DROPDOWN_DESC= "Seleccionar el canal de salida para el comprobador de objetos"

TPERL_CHECK_REPORT_WITHSHORT	= " : %d con"
TPERL_CHECK_REPORT_WITHOUTSHORT	= " : %d sin"
TPERL_CHECK_REPORT_EQUIPEDSHORT	= " : %d equipado/a"
TPERL_CHECK_REPORT_NOTEQUIPEDSHORT	= " : %d NO equipado/a"
TPERL_CHECK_REPORT_OFFLINE	= " : %d desconectado(s)"
TPERL_CHECK_REPORT_TOTAL	= " : %d Objeto(s) Total(es)"
TPERL_CHECK_REPORT_NOTSCANNED	= " : %d deseleccionado(s)"

TPERL_CHECK_LASTINFO		= "Últimos datos recibidos %sago"

TPERL_CHECK_AVERAGE		= "Media"
TPERL_CHECK_TOTALS		= "Total"
TPERL_CHECK_EQUIPED		= "Equipado"

TPERL_CHECK_SCAN_MISSING	= "Escaneando jugadores en rango para el objeto. (%d no escaneados)"

TPERL_REAGENTS			= {PRIEST = "Vela sacra", MAGE = "Partículas Arcanas", DRUID = "Raíz de espina salvaje",
					SHAMAN = "Ankh", WARLOCK = "Fragmento de alma", PALADIN = "Símbolo de Divinidad",
					ROGUE = "Partículas explosivas"}

TPERL_CHECK_REAGENTS		= "Componentes"

-- Roster Text
TPERL_ROSTERTEXT_TITLE		= TPerl_ShortProductName.." Texto Lista"
TPERL_ROSTERTEXT_GROUP		= "Grupo %d"
TPERL_ROSTERTEXT_GROUP_DESC	= "Utilizar nombres del grupo %d"
TPERL_ROSTERTEXT_SAMEZONE	= "Solo Misma Zona"
TPERL_ROSTERTEXT_SAMEZONE_DESC	= "Solo incluir nombres de jugadores que estén en la misma zona que tú"
TPERL_ROSTERTEXT_HELP		= "Pulsa Ctrl-C para copiar el texto en el portapapeles"
TPERL_ROSTERTEXT_TOTAL		= "Total: %d"
TPERL_ROSTERTEXT_SETN		= "%d Hombres"
TPERL_ROSTERTEXT_SETN_DESC	= "Auto-selecciona los grupos para banda de  %d hombres"
TPERL_ROSTERTEXT_TOGGLE		= "Alternar"
TPERL_ROSTERTEXT_TOGGLE_DESC	= "Alternar grupos seleccionados"
TPERL_ROSTERTEXT_SORT		= "Ordenar"
TPERL_ROSTERTEXT_SORT_DESC	= "Ordenar por nombre en lugar de grupo+nombre"
end
