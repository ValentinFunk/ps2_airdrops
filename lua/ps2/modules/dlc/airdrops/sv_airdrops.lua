util.AddNetworkString( "AirDrops_StartPlacement" )

net.Receive( "AirDrops_StartPlacement", function( len, ply )
  if not PermissionInterface.query( ply, 'pointshop2 manageairdrops' ) then
    ply:PS2_DisplayError( "You are not permitted to place Air Drops." )
    return
  end

  if not ply:Alive( ) then
    ply:PS2_DisplayError( "You need to be alive to place Air Drops." )
    return
  end

  -- From DarkRp Copyright (c) 2014 Falco Peijnenburg
  ply.weaponsBeforePlacer = {}
  for k,v in pairs(ply:GetWeapons()) do
      ply.weaponsBeforePlacer[k] = {v:GetClass(), ply:GetAmmoCount(v:GetPrimaryAmmoType()),
      v:GetPrimaryAmmoType(), ply:GetAmmoCount(v:GetSecondaryAmmoType()), v:GetSecondaryAmmoType(),
      v:Clip1(), v:Clip2()}
      /*{class, ammocount primary, type primary, ammo count secondary, type secondary, clip primary, clip secondary*/
  end

  -- Strip Weapons
  ply:StripWeapons( )
  ply:Give( 'weapon_dropplacer' )
  ply:GodEnable( )

  local weapon = ply:GetWeapon( 'weapon_dropplacer' )
  ply:SetActiveWeapon( weapon )
end )

/*
  Creates items but does not save them to the database, they do not have an id!
*/
function Pointshop2.Airdrops.CreateTempItems( amount )
  local dropMap = Pointshop2.GetSetting( "Pointshop 2 DLC", "AirDropsTableSettings.DropsData" )
  local configHasInvalidFactories = false

  --Generate cumulative sum table
	local sumTbl = {}
	local sum = 0
	for k, info in pairs( dropMap ) do
		sum = sum + info.chance
		local factoryClass = getClass( info.factoryClassName )
    if not factoryClass then
      configHasInvalidFactories = true
			continue
		end

		local instance = factoryClass:new( )
		instance.settings = info.factorySettings
    if not instance:IsValid( ) then
      configHasInvalidFactories = true
			continue
		end

		table.insert( sumTbl, {sum = sum, factory = instance, chance = info.chance })
	end

	--Pick element
  local function pickElement( )
  	local r = math.random() * sum
  	local factory, chance
  	for _, info in ipairs( sumTbl ) do
  		if info.sum >= r then
  			factory, chance = info.factory, info.chance
  			break
  		end
  	end

  	if not factory then
  		return
  	end

	  return factory:CreateItem( true ), chance
  end

  local items = { }
  for i = 1, amount do
    local item, chance = pickElement( )
    if item then
      item._airdropChance = chance
      table.insert( items, item )
    end
  end
  return items, configHasInvalidFactories
end

function Pointshop2.Airdrops.ParameterAirdrop( spot )
  local crateContents, configHasInvalidFactories = Pointshop2.Airdrops.CreateTempItems( Pointshop2.GetSetting( "Pointshop 2 DLC", "AirdropCrateSettings.AmountOfItems" ) )
  if #crateContents == 0 then
    for k, v in pairs( player.GetAll( ) ) do
      if v:IsAdmin( ) then
        v:PS2_DisplayError( "[Admin Only] Airdrops setup contains no valid items. An airdrop has been cancelled. Please go into the airdrops configuration and fix crate contents errors." )
      end
    end
    return
  end

  if configHasInvalidFactories then
    for k, v in pairs( player.GetAll( ) ) do
      if v:IsAdmin( ) then
        v:PS2_DisplayError( "[Admin Only] Airdrops setup contains invalid items. Please go into the airdrops configuration and fix crate contents errors." )
      end
    end
  end

  -- Create helicopter
  local helicopter = ents.Create( "sent_supplyhelo" )
  helicopter:SetSpot( spot )
  helicopter:SetCrateContents( crateContents )
  helicopter:Spawn()
  helicopter:Activate()
end

function Pointshop2.Airdrops.StartAirDrop( )
	if not Pointshop2.GetSetting( "Pointshop 2 DLC", "AirDropsSettings.EnableDrops" ) then
		return
	end

  local validSpots = Pointshop2.GetSetting( "Pointshop 2 DLC", "CrateSpotSettings.CrateSpots" )
  if #validSpots == 0 then
    for k, v in pairs( player.GetAll( ) ) do
      if v:IsAdmin( ) then
        v:PS2_DisplayError( "[Admin Only] No airdrop spots are configured for this map. Please set up drop spots." )
      end
    end
    return
  end

  local spot = table.Random( validSpots )
  Pointshop2.Airdrops.ParameterAirdrop( spot )
end

local function getNextTimedAirdrop( )
  local varyPercentage = Pointshop2.GetSetting( "Pointshop 2 DLC", "AirDropsSettings.VaryPercentage" )
  varyPercentage = ( 100 - ( -varyPercentage + ( math.random( ) * varyPercentage * 2 ) ) ) / 100
  local delayInSeconds = varyPercentage * Pointshop2.GetSetting( "Pointshop 2 DLC", "AirDropsSettings.DropFrequency" ) * 60
  return delayInSeconds
end

function Pointshop2.Airdrops.RegisterTimer( )
  timer.Remove( "Pointshop2_Airdrops" )
  -- Integration plugins can have their own logic and call Pointshop2.Airdrops.StartAirDrop( ) directly
  if Pointshop2.IsCurrentGamemodePluginPresent( ) and Pointshop2.GetCurrentGamemodePlugin( ).CustomAirdropTimer then
    return
  end

  local delay = getNextTimedAirdrop( )
	timer.Create( "Pointshop2_Airdrops", delay, 0, function( )
    if #player.GetAll( ) >= Pointshop2.GetSetting( "Pointshop 2 DLC", "AirDropsSettings.MinPlayers" ) then
      Pointshop2.Airdrops.StartAirDrop( )
    else
      KLogf( 4, "[PS2-Airdrops] Not doing airdrop, not enough players online. Required: %i", Pointshop2.GetSetting( "Pointshop 2 DLC", "AirDropsSettings.MinPlayers" ) )
    end

    Pointshop2.Airdrops.RegisterTimer( ) -- Start timer for next drop
  end )
end

hook.Add( "PS2_OnSettingsUpdate", "HandleChangeAirdrops", function( )
	Pointshop2.Airdrops.RegisterTimer( )
end )
Pointshop2.SettingsLoadedPromise:Done( function( )
	Pointshop2.Airdrops.RegisterTimer( )
end )
