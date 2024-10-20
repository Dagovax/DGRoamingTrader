if (!isServer) exitWith {};

if (isNil "DGRT_TraderVehicles") then
{
	["%1 Waiting until configuration completes...", "[DG RoamingTrader]"] call DGCore_fnc_log;
	waitUntil{uiSleep 10; !(isNil "DGRT_TraderVehicles")}
};

["Initializing Roaming Trader", DGRT_MessageName] call DGCore_fnc_log;

/****************************************************************************************************/
/********************************  DO NOT EDIT THE CODE BELOW!!  ************************************/
/****************************************************************************************************/
if(DGRT_DebugMode) then 
{
	['Running in Debug mode!',DGRT_MessageName, "debug"] call DGCore_fnc_log;
	DGRT_MinAmountPlayers	= 0;
	DGRT_WaitTime			= 30;
	//DGRT_UseBuildingPresent = false;
	DGRT_TraderWaitTime		= 30;
	DGRT_InitialWaitTime	= 60;
	DGRT_MaxTraders			= 10;
};

if (DGRT_MinAmountPlayers > 0) then
{
	[format["Waiting for %1 players to be online.", DGRT_MinAmountPlayers], DGRT_MessageName] call DGCore_fnc_log;
	waitUntil { uiSleep 10; count( playableUnits ) > ( DGRT_MinAmountPlayers - 1 ) };
};
[format["%1 players reached. Initializing main loop", DGRT_MinAmountPlayers], DGRT_MessageName] call DGCore_fnc_log;

_middle = worldSize/2;
_center = [_middle,_middle,0];

[format["Waiting %1 seconds until script fireup", DGRT_InitialWaitTime], DGRT_MessageName] call DGCore_fnc_log;
uiSleep DGRT_InitialWaitTime; // Wait initial time

DGRT_RoamingTraderQueue = []; // Active roaming traders. 

_reInitialize = true; // Only initialize this when _reInitialize is true
while {true} do // Main Loop
{	
	if(_reInitialize) then
	{
		_reInitialize = false;
		
		if((count DGRT_RoamingTraderQueue) >= DGRT_MaxTraders) exitWith{}; // We can not spawn any more
		_allBases = nearestObjects [_center , [ "Exile_Construction_Flag_Static" ], 50000 ];
		_traderClass = selectRandom DGRT_TraderTypes;
		if(_traderClass in DGRT_RoamingTraderQueue) exitWith 
		{
			[format["Skipping spawning of trader %1 because there is already one roaming!", _traderClass], DGRT_MessageName] call DGCore_fnc_log;
		};
		if(count _allBases < 1) exitWith{}; // There are no bases!
		_targetBases = [];
		{
			if(DGRT_UseBuildingPresent) then
			{
				_searchRange = _x getVariable [ "ExileTerritorySize", 200 ];
				
				_fndObjects = nearestObjects [ position _x, [DGRT_BuildingRequired], _searchRange ];
				if(count _fndObjects > 0) then
				{
					_firstObj = _fndObjects select 0;
					_targetBases pushBack [_x, true, _firstObj];
					[format ["Adding _targetBase [%1] with present object '%2' @ %3", _x, DGRT_BuildingRequired, _firstObj], DGRT_MessageName, "debug"] call DGCore_fnc_log;
				};
			} else
			{
				_targetBases pushBack [_x, false];
				[format ["Adding _targetBase [%1]", _x], DGRT_MessageName, "debug"] call DGCore_fnc_log;
			};
		} forEach _allBases;
		if(count _targetBases < 1) exitWith{
			["There are no target bases! No roaming trader will spawn this iteration!", DGRT_MessageName] call DGCore_fnc_log;
		};
		
		[_targetBases, _center, _traderClass] spawn
		{
			params ["_targetBases", "_center", "_traderClass"]; // Array of bases to visit as well as center of the map
			if(isNil "_targetBases") exitWith{};
			if (_targetBases isEqualTo []) exitWith{};
			DGRT_RoamingTraderQueue pushBack _traderClass;
			[format ["Spawning a roaming trader that targets [%1] bases: %2", count _targetBases, _targetBases], DGRT_MessageName] call DGCore_fnc_log;
			_routePoints = [];
			{
				_base = _x select 0;
				_usePresentBuildng = _x select 1;
				_pos = getPos _base;
				if(_usePresentBuildng) then
				{
					_buildingPos = _x select 2;
					_pos = getPos _buildingPos;
				};
				_routePoints pushBack _pos;
			} foreach _targetBases;
			[format ["Added [%1] positions: %2", count _routePoints, _routePoints], DGRT_MessageName] call DGCore_fnc_log;
			_vehicleClass = selectRandom DGRT_TraderVehicles;
			_spawnPos = _center;
			_randomBase = (selectRandom _targetBases) select 0;
			_randomPos = [getPos _randomBase,500,4000,2,0,20,0] call BIS_fnc_findSafePos;
			_allRoads = _randomPos nearRoads 1000; // Get all roads near the pos
			if(count _allRoads > 0) then
			{
				_spawnPos = getPos (selectRandom _allRoads);
			} else
			{
				_spawnPos = _randomPos;
			};
			if(DGRT_UseStaticPos) then
			{
				_spawnPos = selectRandom DGRT_StaticPos;
			};
			_vehicleObj = createVehicle [_vehicleClass, _spawnPos, [], 0, "CAN_COLLIDE"];
			_vehicleObj allowDamage false;
			clearBackpackCargoGlobal _vehicleObj;
			clearItemCargoGlobal _vehicleObj;
			clearMagazineCargoGlobal _vehicleObj;
			clearWeaponCargoGlobal _vehicleObj;
			_vehicleObj setVariable ["ExileIsPersistent", false];
			_traderGroup = createGroup independent;
		
			_traderGroup setCombatMode "BLUE";
			_traderGroup setBehaviour "CARELESS";
			_traderGroup setVariable ["_traderClass", _traderClass];
			_trader = _traderGroup createUnit [_traderClass, _spawnPos, [], 0, "NONE"];
			_trader allowDamage false;
			_trader setVariable ["ExileTraderType",_traderClass,true];
			_trader setCaptive true;
			_vehicleObj limitSpeed DGRT_MaxSpeed; // Limit the speed to defined max speed
			_traderGroup setVariable ["_vehicleObj", _vehicleObj];
			_traderName = getText (configFile >> "CfgVehicles" >> (typeOf _trader) >> "displayName");
			
			if(DGRT_AlertTraders) then
			{
				// ["toastRequest", ["InfoEmpty", []]] call ExileServer_system_network_send_broadcast;
				["toastRequest", ["InfoTitleAndText", ["Roaming Trader", format["An %1 has been spotted moving between certain bases!", _traderName]]]] call ExileServer_system_network_send_broadcast;
			};
			
			removeAllWeapons _trader;
			removeBackpack _trader;
			removeVest _trader;
			removeHeadgear _trader;
			removeGoggles _trader;
			_trader forceAddUniform selectRandom DGRT_TraderUniforms;
			_vehicleName = getText (configFile >> "CfgVehicles" >> (typeOf _vehicleObj) >> "displayName");
			[format ["Spawned a %1 at position %2", _vehicleName, _spawnPos], DGRT_MessageName] call DGCore_fnc_log;
			_trader assignasdriver _vehicleObj;
			_trader moveInDriver _vehicleObj;
			{_x disableAI "AUTOTARGET"; _x disableAI "TARGET"; _x disableAI "SUPPRESSION";} forEach units _traderGroup;
			_traderGroup setVariable ["_atPlayerBase", false]; // Initial he is not at a player's base duh
			_traderGroup setVariable ["_spawnPos", _spawnPos]; 
			
			// Event handler for reaching the waypoint
			_traderGroup addEventHandler ["WaypointComplete", {
				_this spawn
				{
					params ["_group", "_waypointIndex"];
					if (isNil "_group" || (isNull _group)) exitWith{}; // Group does not exist anymore
					_trader = leader _group; // Only one unit in this group right?
					[format ["Trader group [%1] triggered WaypointComplete with index: %2 | CurrentWayPoint index = %3 | allWaypoints = %4", _group, _waypointIndex, currentWaypoint _group, waypoints _group], DGRT_MessageName, "debug"] call DGCore_fnc_log;
					_vehicleObj = _group getVariable "_vehicleObj";
					_nearestPos = _group getVariable "_nearestPos";
					_marker = _group getVariable "_marker";
					_currentBase = _group getVariable "_currentBase";
					_baseName = "a player base"; 
					if !(isNil "_currentBase") then
					{
						_baseName = _currentBase getVariable [ "exileterritoryname", "a player base" ];
					};
					if (isNil "_marker") exitWith
					{
						[format["Group %1 reached a waypoint, but they don't have a _marker defined! This is bad...", _group], DGRT_MessageName, "error"] call DGCore_fnc_log;
						_group setVariable ["_atPlayerBase", false];
					};
					_routePoints = _group getVariable "_routePoints";
					_drivingHome = _group getVariable "_drivingHome";
					_traderClass = _group getVariable "_traderClass";
					if (isNil "_nearestPos") exitWith
					{
						[format["Group %1 reached a waypoint, but they don't have a _nearestPos defined! This is bad...", _group], DGRT_MessageName, "error"] call DGCore_fnc_log;
						_group setVariable ["_atPlayerBase", false];
					};
					if (isNil "_vehicleObj") exitWith
					{
						[format["The vehicle of group %1 reached a waypoint, but has no vehicle assigned as variable!", _group], DGRT_MessageName, "error"] call DGCore_fnc_log;
						_group setVariable ["_atPlayerBase", false];
					}; // Vehicle destroyed here
					if (isNil "_routePoints") exitWith
					{
						[format["Group %1 reached a waypoint, but they don't have _routePoints! This is bad...", _group], DGRT_MessageName, "error"] call DGCore_fnc_log;
						_group setVariable ["_atPlayerBase", false];
					};

					// Trader reached waypoint 1, but he is not even close
					_distanceFromObjective = (position _trader) distance2D _nearestPos;
					if (_distanceFromObjective > 100) exitWith
					{
						[format["Group %1 reached a waypoint, but _distanceFromObjective was too high! [%2]", _group, _distanceFromObjective], DGRT_MessageName, "warning"] call DGCore_fnc_log;
						_group setVariable ["_atPlayerBase", false];
						_previousStuckNearestPos = _group getVariable "_previousStuckNearestPos";
						if(!isNil "_previousStuckNearestPos") then
						{
							_checkPos = (position _trader) distance2D _previousStuckNearestPos;
							if(_checkPos < 25) then // Move this guy closer to waypoint
							{
								_curPos = getPos _trader;
								_dirToWaypoint = [_curPos, _nearestPos] call BIS_fnc_dirTo;
								_closerPos = [_curPos, 150, _dirToWaypoint] call BIS_fnc_relPos;
								_randomPos = [_closerPos,0,100,2,0,20,0] call BIS_fnc_findSafePos;
								_allRoads = _randomPos nearRoads 100; // Get all roads near the pos
								if(count _allRoads > 0) then
								{
									_randomPos = getPos (selectRandom _allRoads);
								};
								_vehicleObj setPos _randomPos;
								[format["We moved group %1 to a new _randomPos: [%2]", _group, _randomPos], DGRT_MessageName, "warning"] call DGCore_fnc_log;
							};
						};
						
						_group setVariable ["_previousStuckNearestPos", position _trader];
						[format["Roaming trader group [%1] is now moving to [%2] again, after it was stuck somehow", _group, _nearestPos], DGRT_MessageName, "debug"] call DGCore_fnc_log;
						//_waypoint = (waypoints _group) select 0;
						_waypoint = _group addWaypoint [_nearestPos, 0];
						_waypoint setWaypointType "MOVE";
						_waypoint setWaypointCompletionRadius 25;
						_waypoint setWaypointBehaviour "CARELESS"; 
						// deleteVehicleCrew _vehicleObj;
						// deleteVehicle _vehicleObj;
						// deleteGroup _group;
						// if !(isNil "_traderClass") then
						// {
							// DGRT_RoamingTraderQueue deleteAt (DGRT_RoamingTraderQueue find _traderClass);
						// };
					};
					
					if (isNil "_drivingHome") then
					{
						_drivingHome = false;
					};
					if (_drivingHome) exitWith // Trader reached the end waypoint
					{
						[format["Trader group [%1] reached the end waypoint! Removing it now", _group], DGRT_MessageName, "debug"] call DGCore_fnc_log;
						deleteVehicleCrew _vehicleObj;
						deleteVehicle _vehicleObj;
						{deleteVehicle _x;} forEach units _group;
						deleteGroup _group;
						deleteMarker _marker;
						if !(isNil "_traderClass") then
						{
							DGRT_RoamingTraderQueue deleteAt (DGRT_RoamingTraderQueue find _traderClass);
						};
					};
					
					// Trader reached the target.
					[format["Roaming trader group [%1] reached position [%2] => %3", _group, _nearestPos, _baseName], DGRT_MessageName, "debug"] call DGCore_fnc_log;
					
					if(DGRT_AlertTraders) then
					{
						_traderName = getText (configFile >> "CfgVehicles" >> (typeOf _trader) >> "displayName");
						// ["toastRequest", ["InfoEmpty", []]] call ExileServer_system_network_send_broadcast;
						["toastRequest", ["InfoTitleAndText", [_traderName, format["Reached %1, trading for %2 seconds until I continue!", _baseName, DGRT_TraderWaitTime]]]] call ExileServer_system_network_send_broadcast;
					};
					
					if(DGRT_EnableHorn) then
					{
						_hornSound = selectRandom DGRT_TraderHornSound;
						[_vehicleObj,[_hornSound, 200, 1]] remoteExec ["say3d",0,true];
						uiSleep 0.3;
						[_vehicleObj,[_hornSound, 200, 1]] remoteExec ["say3d",0,true];
					};
					
					_group setVariable ["_atPlayerBase", true];
					_waitTimer = 0;
					_traderMovedOut = false;
					
					// Wait x amount of seconds at a player's base
					while {_waitTimer < DGRT_TraderWaitTime} do
					{
						if(!alive _trader || !alive _vehicleObj) exitWith{};
						_pos = position _vehicleObj;
						_nearPlayers = nearestObjects [_pos, ["Exile_Unit_Player"], DGRT_TraderDistance];
						// _nearPlayers = (count (_pos nearEntities DGRT_TraderDistance select {isPlayer _x}));
						if(count _nearPlayers > 0) then
						{
							if(!_traderMovedOut) then
							{
								[format["Roaming trader [%1] is in range of a player, moving out his vehicle.", _trader], DGRT_MessageName, "debug"] call DGCore_fnc_log;
								_trader action ["salute", _trader];
							};
							_traderMovedOut = true;
							[_trader] orderGetin false;
							_trader disableAI "MOVE";
							_vehicleObj setVehicleLock "LOCKED"; // Locked
						} else
						{
							if(_traderMovedOut) then
							{
								[format["Roaming trader [%1] is out of range of a player, moving inside his vehicle.", _trader], DGRT_MessageName, "debug"] call DGCore_fnc_log;
							};
							_traderMovedOut = false;
							_trader assignasdriver _vehicleObj;
							[_trader] orderGetin true;
							_trader moveInDriver _vehicleObj;
							_trader enableAI "MOVE";
							_vehicleObj setVehicleLock "UNLOCKED"; // Unlocked
						};
						
						uiSleep 1;
						_waitTimer = _waitTimer + 1;
					};
					// Continue again
					_trader assignasdriver _vehicleObj;
					[_trader] orderGetin true;
					_trader moveInDriver _vehicleObj;
					_trader enableAI "MOVE";
					_vehicleObj setVehicleLock "UNLOCKED"; // Locked
					_group setVariable ["_atPlayerBase", false];
					_routePoints deleteAt ( _routePoints find _nearestPos );
					_group setVariable ["_routePoints", _routePoints]; 
					
					if(count _routePoints < 1) then
					{
						_group setVariable ["_drivingHome", true];
						_startPos = _group getVariable "_spawnPos";
						if(isNil "_startPos") exitWith {
							[format["Group %1 Completed all waypoints and wants to move home, but _startPos is undefined!", _group], DGRT_MessageName, "error"] call DGCore_fnc_log;
							deleteVehicleCrew _vehicleObj;
							deleteVehicle _vehicleObj;
							deleteGroup _group;
							deleteMarker _marker;
							if !(isNil "_traderClass") then
							{
								DGRT_RoamingTraderQueue deleteAt (DGRT_RoamingTraderQueue find _traderClass);
							};
						};
						_endWaypoint = _group addWaypoint [_startPos, 25]; // index 2
						_endWaypoint setWaypointType "MOVE";
						_endWaypoint setWaypointCompletionRadius 100;
						_endWaypoint setWaypointBehaviour "CARELESS"; 
						_group setVariable ["_nearestPos", _startPos]; // Update group variable
					} else
					{
						// Get new waypoint location
						_nearestPos = [_routePoints, _trader] call BIS_fnc_nearestPosition;
						[format["Roaming trader group [%1] is now moving to [%2]", _group, _nearestPos], DGRT_MessageName, "debug"] call DGCore_fnc_log;
						_group setVariable ["_nearestPos", _nearestPos]; // Update group variable
						_currentBase = (nearestObjects [_nearestPos , [ "Exile_Construction_Flag_Static" ], 200]) select 0;
						_group setVariable ["_currentBase", _currentBase];
						//_waypoint = (waypoints _group) select 0;
						_waypoint = _group addWaypoint [_nearestPos, 0];
						_waypoint setWaypointType "MOVE";
						_waypoint setWaypointCompletionRadius 25;
						_waypoint setWaypointBehaviour "CARELESS"; 
					};
				};
			}];
			
			// Set initial waypoint
			_nearestPos = [_routePoints, _trader] call BIS_fnc_nearestPosition;
			[format["Roaming trader group [%1] is now moving to [%2]", _traderGroup, _nearestPos], DGRT_MessageName, "debug"] call DGCore_fnc_log;
			_traderGroup setVariable ["_nearestPos", _nearestPos]; // Update group variable
			_waypoint = _traderGroup addWaypoint [_nearestPos, 0];
			_currentBase = (nearestObjects [_nearestPos , [ "Exile_Construction_Flag_Static" ], 200]) select 0;
			_traderGroup setVariable ["_currentBase", _currentBase];
			_waypoint setWaypointType "MOVE";
			_waypoint setWaypointCompletionRadius 25;
			_waypoint setWaypointBehaviour "CARELESS"; 
			_traderGroup setCurrentWaypoint [_traderGroup, 1];
			_traderGroup setVariable ["_routePoints", _routePoints]; 
			[format["Trader group [%1] available wayPoints: %2 | CurrentWayPoint index = %3", _traderGroup, waypoints _traderGroup, currentWaypoint _traderGroup], DGRT_MessageName, "debug"] call DGCore_fnc_log;
			
			_marker = createMarker [format ["%1_%2_%3", "_roamingTrader", _spawnPos select 0, _spawnPos select 1], _spawnPos];
			if (DGRT_EnableMarker) then
			{
				_marker setMarkerType DGRT_MarkerType;
				if(DGRT_EnableMarkerText) then
				{
					_marker setMarkerText _traderName;
				};
				_marker setMarkerColor DGRT_MarkerColor;
				_marker setMarkerSize [0.6, 0.6];
			};
			_traderGroup setVariable ["_marker", _marker]; 
			
			[_vehicleObj, _traderGroup, _marker] spawn
			{
				params ["_vehicleObj", "_traderGroup", "_marker"];
				_traderClass = _traderGroup getVariable "_traderClass";
				if(!isNil "_vehicleObj" && alive _vehicleObj && !isNil "_traderGroup" && !isNull _traderGroup) then // Both vehicle and tradergroup are still alive
				{
					[format["Main loop for Trader group [%1] idle time checker now active", _traderGroup], DGRT_MessageName, "debug"] call DGCore_fnc_log;
					_idleTimer = 0;
					_idleTimeWarning = 20;
					_idleTimeLog = 1; // Factor of above to count how much time it is logged already...
					_idlePosition =  getPos _vehicleObj;
					while {true} do
					{	
						_currentPos = getPos _vehicleObj;	
						if (DGRT_EnableMarker) then
						{
							_marker setMarkerPos _currentPos;
						};						
						if (!alive _vehicleObj || isNil "_traderGroup" || isNull _traderGroup) exitWith
						{
							[format["Group %1 either lost his vehicle or he got killed himself! Removing this trader now", _traderGroup], DGRT_MessageName, "warning"] call DGCore_fnc_log;
							deleteVehicleCrew _vehicleObj;
							deleteVehicle _vehicleObj;
							{deleteVehicle _x;} forEach units _traderGroup;
							deleteGroup _traderGroup;
							deleteMarker _marker;
							if !(isNil "_traderClass") then
							{
								DGRT_RoamingTraderQueue deleteAt (DGRT_RoamingTraderQueue find _traderClass);
							};
						}; 
						
						_atPlayerBase = _traderGroup getVariable "_atPlayerBase";	
						if (isNil "_atPlayerBase") exitWith
						{
							[format["Group %1 has no _atPlayerBase parameter defined at this point: IDLE CHECK LOOP. Removing now", _traderGroup], DGRT_MessageName, "error"] call DGCore_fnc_log;
							deleteVehicleCrew _vehicleObj;
							{deleteVehicle _x;} forEach units _traderGroup;
							deleteVehicle _vehicleObj;
							deleteGroup _traderGroup;
							deleteMarker _marker;
							if !(isNil "_traderClass") then
							{
								DGRT_RoamingTraderQueue deleteAt (DGRT_RoamingTraderQueue find _traderClass);
							};
						};
						
						if(_atPlayerBase) then
						{
							_idleTimer = 0; // Reset idle timer when this guy is at a player's base.
							_idlePosition = _currentPos;
							if(_idleTimeLog > 1) then // Log that the vehicle is not idle anymore
							{
								[format["The %1 is currently trading at a player base @ %2", _vehicleObj, _currentPos], DGRT_MessageName, "debug"] call DGCore_fnc_log;
							};
							_idleTimeLog = 1; // Reset idle time logger
						}
						else
						{
							if ((_currentPos distance2D _idlePosition) <= 25) then 
							{
								_idleTimer = _idleTimer + DGRT_UpdateTime;
								if (_idleTimer > (_idleTimeWarning * _idleTimeLog)) then
								{
									_idleTimeLog = _idleTimeLog + 1;
									[format["The %1 is stuck! Idle now for %2 seconds (max=%3)! Current pos= %4", _vehicleObj, _idleTimer, DGRT_TraderIdleTime, _currentPos], DGRT_MessageName, "warning"] call DGCore_fnc_log;
									[_vehicleObj] call DGCore_fnc_unFlipVehicle; // Checks if vehicle needs to be flipped and does unflip
								};
							} 
							else
							{
								_idlePosition = _currentPos;
								_idleTimer = 0; // Reset the idle timer.
								if(_idleTimeLog > 1) then // Log that the behicle is not idle anymore
								{
									[format["The %1 is not idle anymore. Current pos= %2", _vehicleObj, _currentPos], DGRT_MessageName, "debug"] call DGCore_fnc_log;
								};
								_idleTimeLog = 1; // Reset idle time logger
							};
							
							_vehicleObj setFuel 1;

						};
						uiSleep DGRT_UpdateTime;
						
						if (_idleTimer >= DGRT_TraderIdleTime) exitWith
						{
							[format["Roaming trader group [%1] is stuck, it is idle now for over %2 seconds, while the maximum idle time = %3 seconds. Finishing it off..",_vehicleObj, _idleTimer, DGRT_TraderIdleTime], DGRT_MessageName, "error"] call DGCore_fnc_log;
							deleteVehicleCrew _vehicleObj;
							deleteVehicle _vehicleObj;
							{deleteVehicle _x;} forEach units _traderGroup;
							deleteGroup _traderGroup;
							deleteMarker _marker;
							if !(isNil "_traderClass") then
							{
								DGRT_RoamingTraderQueue deleteAt (DGRT_RoamingTraderQueue find _traderClass);
							};
						};
					};
				};
			};
		};
	};
	_reInitialize = true;
	
	[format["List of active roaming traders [%1]: %2", count DGRT_RoamingTraderQueue, DGRT_RoamingTraderQueue], DGRT_MessageName] call DGCore_fnc_log;
	[format["Waiting %1 seconds for next loop iteration", DGRT_WaitTime], DGRT_MessageName] call DGCore_fnc_log;
	uiSleep DGRT_WaitTime;
}