AirdropsController = class( "AirdropsController" )
AirdropsController:include( BaseController )

function AirdropsController:canDoAction( ply, action )
	local def = Deferred( )

	if action == "addDropSpot" or action == "removeDropSpot" then
    if PermissionInterface.query( ply, 'pointshop2 manageairdrops' ) then
      return Promise.Resolve( )
    end
  end
	if action == "supplyCrateTakeItem" then
		return Promise.Resolve( )
	end

  return Promise.Reject( "Not Permitted" )
end

function AirdropsController:addDropSpot( ply, spot )
  local dbSpot = Pointshop2.AirdropDropSpot:new( )
  dbSpot.map = game.GetMap( )
  dbSpot.pos = spot.pos
  dbSpot.ang = spot.ang
  dbSpot.height = spot.height
  dbSpot.name = spot.name
  return dbSpot:save( )
	:Then( function( spot )
		return spot.id, Pointshop2Controller:getInstance( ):reloadSettings( true )
	end ):Then( function( id )
		return id
	end )
end

function AirdropsController:removeDropSpot( ply, spotId )
  return Pointshop2.AirdropDropSpot.removeWhere{ id = spotId }
	:Then( function( )
		return Pointshop2Controller:getInstance( ):reloadSettings( true )
	end )
end

function AirdropsController:supplyCrateUsed( ply, crate )
	if not IsValid( ply ) or not IsValid( crate ) then
		KLogf( 3, "[CRATE] Invalid arg %s", not IsValid( ply ) and "Player" or "Crate" )
		return
	end

	local contents = crate:GetContents( )
	self:startView( "AirdropsView", "openCrate", ply, crate, contents )
	ply.activeCrate = crate
end

function AirdropsController:supplyCrateTakeItem( ply, index )
	if not IsValid( ply.activeCrate ) then
		KLogf( 3, "Player %s tried to take an item out of a crate, but has no active crate", ply:Nick( ) )
		return Promise.Reject( "Invalid Crate" )
	end

	if ply:GetPos( ):Distance( ply.activeCrate:GetPos( ) ) > Pointshop2.Airdrops.MAX_USE_DISTANCE then
		KLogf( 3, "Player %s tried to take an item out of a crate, but is too far away", ply:Nick( ) )
		return Promise.Reject( "Crate too far away" )
	end

	if not ply:PS2_HasInventorySpace( 1 ) then
		KLogf( 3, "Player %s tried to take an item out of a crate, but has no inventory space", ply:Nick( ) )
		return Promise.Reject( "Inventory Full" )
	end

	local contents = ply.activeCrate:GetContents( )
	local item = contents[index]
	if not item then
		return Promise.Reject( "Invalid Item" )
	end
	if item._airdropsTaken then
		return Promise.Reject( "Already Taken" )
	end
	contents[index]._airdropsTaken = true

	for k, v in pairs( player.GetAll( ) ) do
		if v.activeCrate == ply.activeCrate and v != ply then
			self:startView( "AirdropsView", "crateItemTaken", v, ply.activeCrate, index )
		end
	end

	return Promise.Resolve( )
	:Then( function( )
		local price = item.class:GetBuyPrice( ply )
		item.purchaseData = {
			time = os.time( ),
			origin = "Airdrop"
		}
		if price.points then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "points"
		elseif price.premiumPoints then
			item.purchaseData.amount = price.points
			item.purchaseData.currency = "premiumPoints"
		else
			item.purchaseData.amount = 0
			item.purchaseData.currency = "points"
		end
		return item:save( )
	end )
	:Then( function( item )
		KInventory.ITEMS[item.id] = item
		return ply.PS2_Inventory:addItem( item )
		:Then( function( )
			item:OnPurchased( )
			return item
		end )
	end )
end
