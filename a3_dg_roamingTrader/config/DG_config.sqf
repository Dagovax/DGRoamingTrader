
DGRT_MessageName = "DG RoamingTrader";

if (!isServer) exitWith {
	["Failed to load configuration data, as this code is not being executed by the server!", DGRT_MessageName] call DGCore_fnc_log;
};

["Loading configuration data...", DGRT_MessageName] call DGCore_fnc_log;

// Generic
DGRT_DebugMode			= false; 	// Only for creator. Leave it on false
DGRT_MinAmountPlayers	= 0; 		// Amount of players required to start the missions spawning. Set to 0 to have no wait time for players
DGRT_InitialWaitTime	= 1*60;	// Amount of seconds the script will initial wait to start the loop;
DGRT_WaitTime			= 2*60;		// Amount of seconds the main loop will iterate
DGRT_MaxTraders			= 2;		// Maximum amount of roaming traders at the same time.
DGRT_AlertTraders		= true;		// Gives player information if a trader spawned or reached a new base.
DGRT_TraderIdleTime 	= 120; 	// The maximum number of seconds of vehicle to be idle. (Could be stuck)
DGRT_UpdateTime			= 2; // Seconds to update the position etc..

// Trader config
DGRT_TraderTypes =
[
	"Exile_Trader_Office",
	"Exile_Trader_Armory",
	"Exile_Trader_Equipment",
	"Exile_Trader_Hardware",
	"Exile_Trader_WasteDump",
	"Exile_Trader_SpecialOperations",
	"Exile_Trader_Office",
	"Exile_Trader_Office"
];

DGRT_EnableMarker 		= true; 	// Show a marker at the current position of the trader
DGRT_EnableMarkerText 	= true;		// Show/hide the text displaying the roaming trader type
DGRT_MarkerType			= "ExileTraderZoneIcon";	// Icon type
DGRT_MarkerColor		= "ColorWEST";	// Marker color

DGRT_TraderWaitTime		= 60;		// Amount of seconds a trader will wait at a player's base until moving to the next
DGRT_TraderDistance		= 20; 		// Amount of meters a player has to be in range of the trader to let him move out and stand still while he is waiting
DGRT_EnableHorn			= true;		// Let the car honk when it reached a new position
DGRT_TraderHornSound	= ["DG_CarHorn1", "DG_CarHorn2"];
DGRT_MaxSpeed			= 120;		// Maximum speed of the trader
DGRT_UseBuildingPresent	= true;		// Select only player bases which have a building of type below present. Otherwise, all bases will be used
DGRT_BuildingRequired	= "BDS_Roaming_Trader_Flag";

DGRT_UseStaticPos		= false;
// Array of starting positions. Change these for your own good. If above setting is true, these will be used. Otherwise random spot will be used
DGRT_StaticPos =
[
	[11765.5,9128.74,0],
	[16773.4,5249.91,0],
	[12252.3,15641.2,0],
	[14552.8,16670.8,0],
	[3325.65,5940.45,0],
	[6689.81,16953.8,0],
	[11030.2,2026.16,0],
	[12374.8,8214.7,0]
];

DGRT_TraderUniforms =
[
	"Exile_Uniform_ExileCustoms",
	"Exile_Uniform_Woodland",
	"U_O_V_Soldier_Viper_F",
	"U_B_survival_uniform",
	"U_I_pilotCoveralls"
];

DGRT_TraderVehicles =
[
	"CUP_I_LR_Transport_AAF",
	"I_G_Offroad_01_F",
	"CUP_I_MATV_ION",
	"CUP_I_Pickup_Unarmed_PMC",
	"CUP_I_SUV_ION",
	"CUP_B_LR_Transport_CZ_W",
	"CUP_B_UAZ_Open_ACR",
	"CUP_B_FENNEK_GER_Wdl",
	"CUP_B_M151_HIL",
	// "CUP_B_nM1025_Unarmed_NATO",
	// "CUP_B_nM1038_NATO",
	"B_T_MRAP_01_F",
	"rhsusf_mrzr4_d",
	"rhsusf_m998_w_s_2dr_fulltop",
	"Exile_Car_Lada_Green",
	"Exile_Car_LandRover_Green",
	"Exile_Car_MB4WDOpen",
	"CUP_C_Octavia_CIV",
	// "Exile_Car_UAZ_Open_Green",
	"CUP_C_Golf4_CR_Civ"
];

["Configuration loaded", DGRT_MessageName] call DGCore_fnc_log;
