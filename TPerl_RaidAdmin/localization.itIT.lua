if (GetLocale() == "itIT") then
TPERL_ADMIN_TITLE	= TPerl_ShortProductName.." Amministrazione Raid"

TPERL_MSG_PREFIX	= "|c00C05050TPerl|r "

-- Raid Admin
TPERL_BUTTON_ADMIN_PIN		= "Blocca finestra"
TPERL_BUTTON_ADMIN_LOCKOPEN	= "Blocca finestra aperta"
TPERL_BUTTON_ADMIN_SAVE1	= "Salva formazione"
TPERL_BUTTON_ADMIN_SAVE2	= "Salva la formazione corrente con il nome specificato. Se non viene dato nessun nome, verrà usata l'ora corrente come nome"
TPERL_BUTTON_ADMIN_LOAD1	= "Carica formazione"
TPERL_BUTTON_ADMIN_LOAD2	= "Carica la formazione selzionata. Se ci sono dei membri mancanti, verranno sostituiti con altri della stessa classe che non erano salvati nella formazione"
TPERL_BUTTON_ADMIN_DELETE1	= "Elimina formazione"
TPERL_BUTTON_ADMIN_DELETE2	= "Elimina la formazione selzionata"
TPERL_BUTTON_ADMIN_STOPLOAD1	= "Blocca caricamento"
TPERL_BUTTON_ADMIN_STOPLOAD2	= "Interrompe la procedura di caricamento della formazione"

TPERL_LOAD			= "Carica"

TPERL_SAVED_ROSTER		= "Formazione salvata come '%s'"
TPERL_ADMIN_DIFFERENCES		= "%d rispetto alla formazione corrente"
TPERL_NO_ROSTER_NAME_GIVEN	= "Nessun nome è stato assegnato per la formazione"
TPERL_NO_ROSTER_CALLED		= "Nessuna formazione salvata chiamata '%s'"

-- Item Checker
TPERL_CHECK_TITLE		= TPerl_ShortProductName.." Controllo Oggetti"

TPERL_CHECK_NAME		= "Nome"

TPERL_CHECK_DROPITEMTIP1	= "Drag-Drop Oggetti"
TPERL_CHECK_DROPITEMTIP2	= "Gli oggetti possono essere trascinati in questa finestra per aggiungerli alla lista degli oggetti da controllare.\rPuoi anche usare il comando /raitem."
TPERL_CHECK_QUERY_DESC1		= "Controlla"
TPERL_CHECK_QUERY_DESC2		= "Esegue il controllo (/raitem) su tutti gli oggetti selezionati\rLa ricerca fornisce diverse informazioni sugli oggetti"
TPERL_CHECK_LAST_DESC1		= "Ultimi"
TPERL_CHECK_LAST_DESC2		= "Seleziona gli oggetti che hai controllato l'ultima volta"
TPERL_CHECK_ALL_DESC1		= ALL
TPERL_CHECK_ALL_DESC2		= "Seleziona tutti gli oggetti"
TPERL_CHECK_NONE_DESC1		= NONE
TPERL_CHECK_NONE_DESC2		= "Deseleziona tutti gli oggetti"
TPERL_CHECK_DELETE_DESC1	= DELETE
TPERL_CHECK_DELETE_DESC2	= "Rimuovi tutti gli oggetti seleziona dalla lista"
TPERL_CHECK_REPORT_DESC1	= "Riporta"
TPERL_CHECK_REPORT_DESC2	= "Visualizza i risultati nella chat del incursione"
TPERL_CHECK_REPORT_WITH_DESC1	= "Con"
TPERL_CHECK_REPORT_WITH_DESC2	= "Visualizza i giocatori con l'oggetto (o che non ce l'hanno equipaggiato) nella chat del incursione. Se è stato effettuato un controllo equipaggiamenti, questi risultati verranno visualizzati."
TPERL_CHECK_REPORT_WITHOUT_DESC1= "Senza"
TPERL_CHECK_REPORT_WITHOUT_DESC2= "Visualizza i giocatori senza l'oggetto (o che ce l'hanno equipaggiato) nella chat del incursione."
TPERL_CHECK_SCAN_DESC1		= "Scansiona"
TPERL_CHECK_SCAN_DESC2		= "Controllerà chiunque del raid abbastanza vicino per effettuare un'ispezione dell'equipaggiamento, per vedere se ha l'oggetto selezionato equipaggiato e questo verrà indicato nella lista dei giocatore. Avvicinati agli altri giocatori del incursione fino a quando non sono stati tutti controllati."
TPERL_CHECK_SCANSTOP_DESC1	= "Interrompi scansione"
TPERL_CHECK_SCANSTOP_DESC2	= "Interrompi la scansione dei giocatori per l'oggetto selezionato"
TPERL_CHECK_REPORTPLAYER_DESC1	= "Segnala giocatore"
TPERL_CHECK_REPORTPLAYER_DESC2	= "Segnala i dettagli del giocatore per questo oggetto o stato nella chat dell'incursione"

TPERL_CHECK_BROKEN		= "Rotto"
TPERL_CHECK_REPORT_DURABILITY	= "Rottura dell'equipaggamento media dei membri: %d%% e %d persone con un totale di %d oggetti rotti"
TPERL_CHECK_REPORT_PDURABILITY	= "%s's Durability: %d%% with %d broken items"
TPERL_CHECK_REPORT_RESISTS	= "Average Raid resists: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_PRESISTS	= "%s's Resists: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_WITH		= " - with: "
TPERL_CHECK_REPORT_WITHOUT	= " - without: "
TPERL_CHECK_REPORT_WITH_EQ	= " - with (or not equipped): "
TPERL_CHECK_REPORT_WITHOUT_EQ	= " - without (or equipped): "
TPERL_CHECK_REPORT_EQUIPED	= " : equipped: "
TPERL_CHECK_REPORT_NOTEQUIPED	= " : NOT equipped: "
TPERL_CHECK_REPORT_ALLEQUIPED	= "Everyone has %s equipped"
TPERL_CHECK_REPORT_ALLEQUIPEDOFF= "Everyone has %s equipped, but %d member(s) offline"
TPERL_CHECK_REPORT_PITEM	= "%s has %d %s in inventory"
TPERL_CHECK_REPORT_PEQUIPED	= "%s has %s equipped"
TPERL_CHECK_REPORT_PNOTEQUIPED	= "%s DOES NOT have %s equipped"
TPERL_CHECK_REPORT_DROPDOWN	= "Output Channel"
TPERL_CHECK_REPORT_DROPDOWN_DESC= "Select output channel for Item Checker results"

TPERL_CHECK_REPORT_WITHSHORT	= " : %d with"
TPERL_CHECK_REPORT_WITHOUTSHORT	= " : %d without"
TPERL_CHECK_REPORT_EQUIPEDSHORT	= " : %d equipped"
TPERL_CHECK_REPORT_NOTEQUIPEDSHORT	= " : %d NOT equipped"
TPERL_CHECK_REPORT_OFFLINE	= " : %d offline"
TPERL_CHECK_REPORT_TOTAL	= " : %d Total Items"
TPERL_CHECK_REPORT_NOTSCANNED	= " : %d un-checked"

TPERL_CHECK_LASTINFO		= "Last data received %sago"

TPERL_CHECK_AVERAGE		= "Average"
TPERL_CHECK_TOTALS		= "Total"
TPERL_CHECK_EQUIPED		= "Equipped"

TPERL_CHECK_SCAN_MISSING	= "Scanning inspectable players for item. (%d un-scanned)"

TPERL_REAGENTS			= {PRIEST = "Sacred Candle", MAGE = "Arcane Powder", DRUID = "Wild Thornroot",
					SHAMAN = "Ankh", WARLOCK = "Soul Shard", PALADIN = "Symbol of Divinity",
					ROGUE = "Flash Powder"}

TPERL_CHECK_REAGENTS		= "Reagents"

-- Roster Text
TPERL_ROSTERTEXT_TITLE		= TPerl_ShortProductName.." Roster Text"
TPERL_ROSTERTEXT_GROUP		= "Group %d"
TPERL_ROSTERTEXT_GROUP_DESC	= "Use names from group %d"
TPERL_ROSTERTEXT_SAMEZONE	= "Same Zone Only"
TPERL_ROSTERTEXT_SAMEZONE_DESC	= "Only include names of players in the same zone as yourself"
TPERL_ROSTERTEXT_HELP		= "Press Ctrl-C to copy the text to the clipboard"
TPERL_ROSTERTEXT_TOTAL		= "Total: %d"
TPERL_ROSTERTEXT_SETN		= "%d Man"
TPERL_ROSTERTEXT_SETN_DESC	= "Auto select the groups for a %d man raid"
TPERL_ROSTERTEXT_TOGGLE		= "Toggle"
TPERL_ROSTERTEXT_TOGGLE_DESC	= "Toggle the selected groups"
TPERL_ROSTERTEXT_SORT		= "Sort"
TPERL_ROSTERTEXT_SORT_DESC	= "Sort by name instead of by group+name"
end
