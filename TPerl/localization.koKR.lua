-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if (GetLocale() == "koKR") then
	TPERL_MINIMAP_HELP1	= "|c00FFFFFF좌클릭|r 하시면 설정창이 나옵니다. (그리고 |c0000FF00프레임 고정|r이 풀립니다.)"
	TPERL_MINIMAP_HELP2	= "|c00FFFFFF우클릭|r 으로 버튼을 드래그해서 이동가능합니다."
	TPERL_MINIMAP_HELP3	= "\r실제 공대원: |c00FFFF80%d|r\r실제 파티원: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4	= "\r당신은 실제 파티/공격대장 입니다."
	TPERL_MINIMAP_HELP5	= "|c00FFFFFFALT|r : X-Perl 메모리 사용량"
	TPERL_MINIMAP_HELP6	= "|c00FFFFFF+SHIFT|r : 접속 후 X-Perl 메모리 사용량"

	TPERL_MINIMENU_OPTIONS	= "설정"
	TPERL_MINIMENU_ASSIST	= "어시스트 창 표시"
	TPERL_MINIMENU_CASTMON	= "시전 현황 표시"
	TPERL_MINIMENU_RAIDAD	= "공격대 관리 표시"
	TPERL_MINIMENU_ITEMCHK	= "아이템 체커 표시"
	TPERL_MINIMENU_RAIDBUFF = "공격대 버프"
	TPERL_MINIMENU_ROSTERTEXT="명부 글자"
	TPERL_MINIMENU_RAIDSORT = "공격대 정렬"
	TPERL_MINIMENU_RAIDSORT_GROUP = "파티별 정렬"
	TPERL_MINIMENU_RAIDSORT_CLASS = "직업별 정렬"

	TPERL_TYPE_NOT_SPECIFIED = "무엇인가"
	TPERL_TYPE_BOSS		= "보스"
	TPERL_TYPE_RAREPLUS	= "희귀 정예"
	TPERL_TYPE_ELITE	= "정예"
	TPERL_TYPE_RARE		= "희귀"

	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "불뱀 제단"
	TPERL_LOC_ZONE_BLACK_TEMPLE = "검은 사원"
	TPERL_LOC_ZONE_HYJAL_SUMMIT = "하이잘 정상"
	TPERL_LOC_ZONE_KARAZHAN = "카라잔"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU = "태양샘 고원"
	TPERL_LOC_ZONE_ULDUAR = "울두아르"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "십자군의 시험장"
	TPERL_LOC_ZONE_ICECROWN_CITADEL = "얼음왕관 성채"
	TPERL_LOC_ZONE_RUBY_SANCTUM = "루비 성소"

	TPERL_LOC_GHOST		= "유령"
	TPERL_LOC_FEIGNDEATH	= "죽은척하기"
	TPERL_LOC_RESURRECTED	= "부활"
	TPERL_LOC_SS_AVAILABLE	= "영혼석 있음"
	TPERL_LOC_UPDATING	= "업데이트"
	TPERL_LOC_ACCEPTEDRES	= "수락됨"
	TPERL_RAID_GROUP	= "%d 파티"
	TPERL_RAID_GROUPSHORT	= "%d파"

	TPERL_LOC_NONEWATCHED	= "발견된 사항 없음"

	TPERL_LOC_STATUSTIP	= "상태 강조: "		-- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "주기적인 치유",
		AGGRO = "어그로",
		MISSING = "당신의 직업 버프 누락",
		HEAL = "치유 중",
		SHIELD = "보호막"
	}

	TPERL_OK		= "확인"
	TPERL_CANCEL		= "취소"

	TPERL_LOC_LARGENUMTAG		= "K"
	TPERL_LOC_HUGENUMTAG		= "M"
	TPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_TPERL = "TPerl 단축키 설정"
	BINDING_NAME_TPERL_TOGGLERAID = "공격대 창 켜기/끄기"
	BINDING_NAME_TPERL_TOGGLERAIDSORT = "공격대 정렬 직업별/파티별"
	BINDING_NAME_TPERL_TOGGLERAIDPETS = "공격대 소환수창 켜기/끄기"
	BINDING_NAME_TPERL_TOGGLEOPTIONS = "설정창 열기/닫기"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE = "버프/디버프/없음 변경"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE = "시전가능/해제가능 변경"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR = "음성대화 현황"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER = "거리 측정 켜기/끄기"

	TPERL_KEY_NOTICE_RAID_BUFFANY = "모든 버프/디버프 표시"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST = "오직 시전가능/해제가능 한 버프 또는 디버프만 표시"
	TPERL_KEY_NOTICE_RAID_BUFFS = "공격대 버프 표시"
	TPERL_KEY_NOTICE_RAID_DEBUFFS = "공격대 디버프 표시"
	TPERL_KEY_NOTICE_RAID_NOBUFFS = "공격대 버프 표시안함"

	TPERL_DRAGHINT1		= "창 비율을 조절하려면 |c00FFFFFF클릭|r하세요."
	TPERL_DRAGHINT2		= "창 크기를 조절하려면 |c00FFFFFFSHIFT+클릭|r하세요."

	-- 사용법
	TPerlUsageNameList	= {TPerl = "코어", TPerl_Player = "플레이어", TPerl_PlayerPet = "소환수", TPerl_Target = "대상", TPerl_TargetTarget = "대상의 대상", TPerl_Party = "파티", TPerl_PartyPet = "파티 소환수", TPerl_RaidFrames = "공격대 창", TPerl_RaidHelper = "공격대 도우미", TPerl_RaidAdmin = "공격대 관리", TPerl_TeamSpeak = "음성대화 현황", TPerl_RaidMonitor = "공격대 현황", TPerl_RaidPets = "공격대 소환수", TPerl_ArcaneBar = "아케인 바", TPerl_PlayerBuffs = "플레이어 버프", TPerl_GrimReaper = "Grim Reaper"}
	TPERL_USAGE_MEMMAX	= "UI 메모리 최대값 : %d"
	TPERL_USAGE_MODULES	= "모듈: "
	TPERL_USAGE_NEWVERSION	= "*새로운 버전"
	TPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r : 다운로드 가능"


	TPERL_CMD_HELP			= "|c00FFFF80사용법: |c00FFFFFF/xperl menu | lock | unlock | config list | config delete <서버> <이름>"
	TPERL_CANNOT_DELETE_CURRENT 	= "현재 설정은 삭제할 수 없습니다."
	TPERL_CONFIG_DELETED		= "%s/%s 설정이 삭제되었습니다."
	TPERL_CANNOT_FIND_DELETE_TARGET = "삭제할 설정을 찾을 수 없습니다. (%s/%s)"
	TPERL_CANNOT_DELETE_BADARGS 	= "서버명과 플레이어 이름을 입력하세요."
	TPERL_CONFIG_LIST		= "설정 목록:"
	TPERL_CONFIG_CURRENT		= " (현재)"

	TPERL_RAID_TOOLTIP_WITHBUFF	= "버프있음: (%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF	= "버프없음: (%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s의 %s %s 이내 사라짐"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED = "새로운 버전이 발견되었습니다."
end
