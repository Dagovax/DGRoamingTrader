waitUntil {uiSleep 5; !(isNil "DGCore_Initialized")}; // Wait until DGCore was initialized

["Starting DagovaxGames Roaming Trader"] call DGCore_fnc_log;
execvm "\x\addons\a3_dg_roamingTrader\config\DG_config.sqf";
execvm "\x\addons\a3_dg_roamingTrader\init\roamingTrader.sqf";
