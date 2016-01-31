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
