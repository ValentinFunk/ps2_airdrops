hook.Add( "PS2_ModulesLoaded", "DLC_AirDrops", function( )
	local MODULE = Pointshop2.GetModule( "Pointshop 2 DLC" )

	MODULE.Settings.Server.AirDropsTableSettings = {
		info = {
			label = "Airdrops Contents Settings",
			isManualSetting = true, --Ignored by AutoAddSettingsTable
		},
		DropsData = {
			value = { },
			type = "table"
		}
	}

	MODULE.Settings.Server.CrateSpotSettings = {
		info = {
			isManualSetting = true,
			noDbSetting = true --Never save these to DB
		},
		/*
		This section is placed here dynamically:
		CrateSpots = {
			value = { },
			type = "table"
		}
		*/
	}

	MODULE.Settings.Server.AirDropsSettings = {
		info = {
			label = "General Settings",
		},
		EnableDrops = {
			value = true,
			label = "Enable Airdrops system",
		},
		DropFrequency = {
			value = 10,
			label = "Drop frequency (in minutes)",
			tooltip = "Set the drop frequency."
		},
    VaryPercentage = {
      value = 20,
      label = "Drop frequency random variation (in percent)",
      tooltip = "Make drops less predictable: If this is set to 20%, and drop frequency is set to 10 min, the actual drop frequency will be between 8 and 12 minutes."
    },
		MinPlayers = {
			value = 4,
			label = "Minumum Players",
			tooltip = "Minimum amount of players for a crate to drop"
		}
	}

	if SERVER then
		CreateConVar("pointshop2_airdrops_salt", "{{ user_id | 69 }}", {FCVAR_NOTIFY, FCVAR_REPLICATED})
	end

	MODULE.Settings.Server.AirdropCrateSettings = {
		info = {
			label = "Crate Settings",
		},
		AmountOfItems = {
			value = 5,
			label = "Amount of items in a crate",
		},
		CrateLifetime = {
			value = 3,
			label = "Lifetime (in minutes)",
			tooltip = "Time until a crate is automatically removed"
		}
	}

	local old = MODULE.Resolve or Promise.Resolve
	MODULE.Resolve = function( )
		return old( ):Then( function( )
			return Pointshop2.AirdropDropSpot.findWhere{ map = game.GetMap( ) }
			:Then( function( spots )
				MODULE.Settings.Server.CrateSpotSettings.CrateSpots = {
					value = { },
					type = "table"
				}

				MODULE.Settings.Server.CrateSpotSettings.CrateSpots.value = LibK._.map( spots, function( spot )
					-- Clean class metainfo and pass only model fields into the settings table
					local tab = {
						id = spot.id
					}
					LibK.copyModelFields( tab, spot, Pointshop2.AirdropDropSpot.model )
					return tab
				end )
			end )
		end )
	end
end )

Pointshop2.Airdrops = {}
Pointshop2.Airdrops.MAX_USE_DISTANCE = 300

-- DO NOT REMOVE THIS LINE:
print( "Pointshop2 Airdrops", "{{ user_id }}" )
