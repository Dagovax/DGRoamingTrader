class CfgPatches {
	class a3_dg_roamingTrader {
		units[] = {};
		weapons[] = {};
		requiredVersion = 0.1;
		requiredAddons[] = {};
	};
};
class CfgFunctions {
	class DGRoamingTrader {
		tag = "DGRoamingTrader";
		class Main {
			file = "\x\addons\a3_dg_roamingTrader\init";
			class init {
				postInit = 1;
			};
		};
	};
};

