if (GetLocale() == "frFR") then
TPERL_ADMIN_TITLE			= "TPerl Raid Admin"

TPERL_MSG_PREFIX	        	= "|c00C05050TPerl|r "

-- Raid Admin
TPERL_BUTTON_ADMIN_PIN			= "V\195\169rrou de fen\195\170tres"
TPERL_BUTTON_ADMIN_LOCKOPEN		= "V`195`169rouille les fen\195\170tres ouvertes"
TPERL_BUTTON_ADMIN_SAVE1		= "Sauvegarder le roster"
TPERL_BUTTON_ADMIN_SAVE2		= "Sauve la disposition courante de r\195\180le avec le nom indiqu\195\169. Si aucun nom donn\195\169, le temps courant ne sera employ\195\169 comme nom"
TPERL_BUTTON_ADMIN_LOAD1		= "Charger le roster"
TPERL_BUTTON_ADMIN_LOAD2		= "Charger le r\195\180le choisi. En pillent les membres du r\195\180le sauv\195\169 qui sont plus dans l'incursion ne seront remplac\195\169s par les membres de la m\195\170me classe qui ne sont pas sauv\195\169s dans le r\195\180le"
TPERL_BUTTON_ADMIN_DELETE1		= "Effacement du roster"
TPERL_BUTTON_ADMIN_DELETE2		= "Efface le roster s\195\169l\195\169ctionn\195\169"
TPERL_BUTTON_ADMIN_STOPLOAD1		= "Arr\195\170te le chargement"
TPERL_BUTTON_ADMIN_STOPLOAD2		= "Interrompre le chargement du roster"

TPERL_LOAD                     	 	= "Lancer"

TPERL_SAVED_ROSTER			= "Roster sauvegard\195\169 est appell\195\169 '%s'"
TPERL_ADMIN_DIFFERENCES			= "%d differences avec le roster en cours"
TPERL_NO_ROSTER_NAME_GIVEN		= "Pas de nom de roster donn\195\169"
TPERL_NO_ROSTER_CALLED			= "Pas de roster sauvegard\195\169 appell\195\169 '%s'"

-- Item Checker
TPERL_CHECK_TITLE			= "TPerl V\195\169rificateur d'articles"

TPERL_CHECK_NAME			= "Noms"

TPERL_CHECK_DROPITEMTIP1		= "Articles rammass\195\169s"
TPERL_CHECK_DROPITEMTIP2		= "Des articles peuvent \195\170tre l\195\162chés dans ce cadre et \195\170tre ajout\195\169s \195\160 la liste d'articles questionnable. Vous pouvez \195\169galement employer la commande de /raitem comme normale et des articles \195\169galement seront ajout\195\169s ici et \195\160 l'avenir employ\195\169s."
TPERL_CHECK_QUERY_DESC1			= "Qestion"
TPERL_CHECK_QUERY_DESC2			= "Ex\195\169cute le contr81958180le d'article (/raitem) sur tous les articles La question obtient toujours le durablity, la résistance et l'information courants de réactifs"
TPERL_CHECK_LAST_DESC1			= "derni\195\168res"
TPERL_CHECK_LAST_DESC2			= "Re-tick la derni\195\168res recherche d'articles"
TPERL_CHECK_ALL_DESC1			= ALL
TPERL_CHECK_ALL_DESC2			= "Tick tout les articles"
TPERL_CHECK_NONE_DESC1			= NONE
TPERL_CHECK_NONE_DESC2			= "Un-tick tous les articles"
TPERL_CHECK_DELETE_DESC1		= DELETE
TPERL_CHECK_DELETE_DESC2		= "Efface tous les ticks d'articles de la liste"
TPERL_CHECK_REPORT_DESC1		= "Rapport"
TPERL_CHECK_REPORT_DESC2		= "Montre les rapports des r\195\169sutats s\195\169l\195\169ctionn\195\169 dans le chat de raid"
TPERL_CHECK_REPORT_WITH_DESC1		= "avec"
TPERL_CHECK_REPORT_WITH_DESC2		= "Rapporter les personnes avec l'article (ou qui ne l'on pas \195\169quip\195\169) dans le chat de raid"
TPERL_CHECK_REPORT_WITHOUT_DESC1	= "Sans"
TPERL_CHECK_REPORT_WITHOUT_DESC2	= "Rapporter les personnes sans  l'article (ou avoir l'article \195\169quip\195\169) dans le chat de raid "
TPERL_CHECK_SCAN_DESC1			= "Scan"
TPERL_CHECK_SCAN_DESC2			= ""
TPERL_CHECK_SCANSTOP_DESC1		= "Arretez le scan"
TPERL_CHECK_SCANSTOP_DESC2		= ""
TPERL_CHECK_REPORTPLAYER_DESC1		= "Rapportez au joueur"
TPERL_CHECK_REPORTPLAYER_DESC2		= ""

TPERL_CHECK_BROKEN			= "Durabilit\195\169"
TPERL_CHECK_REPORT_DURABILITY		= " Moyenne de la durabilit\195\169 du raid %d%% et %d les personnes avec un total de %d d'articles cass\195\169s"
TPERL_CHECK_REPORT_PDURABILITY		= "%s durabilit\195\169: %d%% avec %d d'articles cass\195\169s"
TPERL_CHECK_REPORT_RESISTS		= "Moyenne de r\195\169sistance du raid %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_PRESISTS		= "%s R\195\169sistances %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_WITH			= " - avec : "
TPERL_CHECK_REPORT_WITHOUT		= " - sans : "
TPERL_CHECK_REPORT_WITH_EQ		= " - avec (ou pas \195\169qui\195\169): "
TPERL_CHECK_REPORT_WITHOUT_EQ		= " - sans (ou \195\169quip\195\169): "
TPERL_CHECK_REPORT_EQUIPED		= " : equp\195\169: "
TPERL_CHECK_REPORT_NOTEQUIPED		= " : non-\195\169quip\195\169: "
TPERL_CHECK_REPORT_ALLEQUIPED		= "Chacun a \195\169t\195\169 %s \195\169quip\195\169"
TPERL_CHECK_REPORT_ALLEQUIPEDOFF	= "Chacun a \195\169t\195\169 %s \195\169quip\195\169, mais %d sont hors-ligne"
TPERL_CHECK_REPORT_PITEM		= "%s \195\160 \195\169t\195\169 %d %s dans les inventaires"
TPERL_CHECK_REPORT_PEQUIPED		= "%s \195\160 \195\169t\195\169 %s \195\169quip\195\169"
TPERL_CHECK_REPORT_PNOTEQUIPED		= "%s n'as pas \195\169t\195\169 %s \195\169quip\195\169"
TPERL_CHECK_REPORT_DROPDOWN		= "Canaux de sorties"
TPERL_CHECK_REPORT_DROPDOWN_DESC	= "S\195\169l\195\169ctionne le canal de sortie pour le r\195\169sultat du controle d'articles"

TPERL_CHECK_REPORT_WITHSHORT		= " : %d avec"
TPERL_CHECK_REPORT_WITHOUTSHORT		= " : %d sans"
TPERL_CHECK_REPORT_EQUIPEDSHORT		= " : %d equip\195\169"
TPERL_CHECK_REPORT_NOTEQUIPEDSHORT 	= " : %d non-\195\169quip\195\169"
TPERL_CHECK_REPORT_OFFLINE		= " : %d hors-ligne"
TPERL_CHECK_REPORT_TOTAL		= " : %d Total d'articles"
TPERL_CHECK_REPORT_NOTSCANNED		= " : %d non-recherch\195\169"

TPERL_CHECK_LASTINFO			= "Derni\195\168res donn\195\169es recu il y \195\160 % "

TPERL_CHECK_AVERAGE			= "Moyenne"
TPERL_CHECK_TOTALS			= "Total"
TPERL_CHECK_EQUIPED			= "Equip\195\169"

TPERL_CHECK_SCAN_MISSING		= "Scan d'inspection des joueurs pour l'article (%d non-trouv\195\169)"

TPERL_REAGENTS				= {PRIEST = "Bougie sacr\195\169e", MAGE = "Poudre des arcanes", DRUID = "Ronceterre sauvage",
					SHAMAN = "Croix", WARLOCK = "Fragment d'\195\162me", PALADIN = "Symbole de divinit\195\169",
					ROGUE = "Poudre \195\169clipsante"}

TPERL_CHECK_REAGENTS			= "R\195\169actifs"

-- Roster Text
TPERL_ROSTERTEXT_GROUP			= "Groupe %d"
end
