-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if (GetLocale() == "frFR") then
	TPerl_LongDescription = "UnitFrame replacement for new look Joueur, Familier, Groupe, Cible, Cible de la cible, Raid"
	TPERL_MINIMAP_HELP1 = "|c00FFFFFFClique gauche pour options"
	TPERL_MINIMAP_HELP2 = "|c00FFFFFFClique droit pour bouger l'ic\195\180ne"
	TPERL_MINIMAP_HELP3 = "\rReal Raid Members: |c00FFFF80%d|r\rReal Party Members: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4 = "\rYou are leader of the real party/raid"

	TPERL_TYPE_NOT_SPECIFIED = "Non indiqu\195\169"

	TPERL_TYPE_PET = "Familiers"

	TPERL_LOC_CLASS_WARRIORFEM = "Guerri\195\168re"
	TPERL_LOC_CLASS_ROGUEFEM = "Voleuse"
	TPERL_LOC_CLASS_DRUIDFEM = "Druidesse"
	TPERL_LOC_CLASS_HUNTERFEM = "Chasseresse"
	TPERL_LOC_CLASS_SHAMANFEM = "Chamane"
	TPERL_LOC_CLASS_PRIESTFEM = "Pr\195\170tresse"

	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "Caverne du sanctuaire du Serpent"
	TPERL_LOC_ZONE_BLACK_TEMPLE = "Temple noir"
	TPERL_LOC_ZONE_HYJAL_SUMMIT = "Sommet d'Hyjal"
	TPERL_LOC_ZONE_KARAZHAN = "Karazhan"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU = "Plateau du Puits de soleil"
	TPERL_LOC_ZONE_ULDUAR = "Ulduar"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "L'épreuve du croisé"
	TPERL_LOC_ZONE_ICECROWN_CITADEL = "Citadelle de la Couronne de glace"
	TPERL_LOC_ZONE_RUBY_SANCTUM = "Le sanctum Rubis"

	TPERL_LOC_DEAD = "Mort"
	TPERL_LOC_GHOST = "Fant\195\180me"
	TPERL_LOC_FEIGNDEATH = "Feindre la Mort"
	TPERL_LOC_OFFLINE = "Hors-ligne"
	TPERL_LOC_RESURRECTED = "R\195\169ssusict\195\169"
	TPERL_LOC_SS_AVAILABLE = "SS Available"
	TPERL_LOC_UPDATING = "Mise \195\162 jour"
	TPERL_LOC_ACCEPTEDRES = "Accepter la r\195\169sur\195\169ction" -- Res accepted
	TPERL_RAID_GROUP = "Groupe %d"

	TPERL_LOC_STATUSTIP = "Statuts accentu\195\169s: " -- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "Soins sur la dur\195\169e",
		AGGRO = "Aggro",
		MISSING = "Manque votre buff de classe",
		HEAL = "Viens d'\195\170tre soign\195\169",
		SHIELD = "envellop\195\169 d'un bouclier"
	}

	TPERL_OK = "Ok"
	TPERL_CANCEL = "Annuler"

	TPERL_LOC_LARGENUMTAG		= "K"
	TPERL_LOC_HUGENUMTAG		= "M"
	TPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_TPERL = "TPerl Key Bindings"
	BINDING_NAME_TPERL_TOGGLERAID = "D\195\169scriptif de raid"
	BINDING_NAME_TPERL_TOGGLERAIDSORT = "D\195\169scriptif de raid assorti par classe/groupe"
	BINDING_NAME_TPERL_TOGGLEOPTIONS = "Bascule de la fen\195\170tre d'options"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE = "Bascule aucun buffs/debuffs"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE = "Bascule lanceable/soignable"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR = "Moniteur Teamspeack"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER = "Bascule du t\195\169l\195\169m\195\169tre"

	TPERL_KEY_NOTICE_RAID_BUFFANY = "Montrer tout les buffs/debuffs"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Ne montrer que les Buffs/Debuffs que l'on peux soigner"
	TPERL_KEY_NOTICE_RAID_BUFFS = "Montrer les buffs du raid"
	TPERL_KEY_NOTICE_RAID_DEBUFFS = "Montrer les debuffs du raid"
	TPERL_KEY_NOTICE_RAID_NOBUFFS = "Ne pas montrer les debuffs du raid"

	TPERL_RAID_TOOLTIP_WITHBUFF			= "Avec buffs: (%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF		= "Sans buffs: (%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING		= "%s's %s expires dans %s"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED = "Nouvelle version détectée:"
end
