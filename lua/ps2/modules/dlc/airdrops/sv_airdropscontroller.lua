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

	ply.activeCrate.itemsTaken = ply.activeCrate.itemsTaken or {}
	ply.activeCrate.itemsTaken[ply] = ply.activeCrate.itemsTaken[ply] or 0
	if ply.activeCrate.itemsTaken[ply] >= Pointshop2.GetSetting( "Pointshop 2 DLC", "AirdropCrateSettings.MaxItemsPerPlayer" ) then
		KLogf( 3, "Player %s tried to take an item out of a crate, but has already taken max amount of items", ply:Nick( ) )
		return Promise.Reject( "You have already taken the maximum amount of items out of this crate" )
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

	-- Remove crate if empty
	local allTaken = true
	for k, v in pairs(contents) do
		if not v._airdropsTaken then
			allTaken = false
		end
	end
	if allTaken then
		ply.activeCrate:Remove( )
	end

	ply.activeCrate.itemsTaken[ply] = ply.activeCrate.itemsTaken[ply] + 1
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
		return item --item:save( ) is done by KInventory:addItem
	end )
	:Then( function( item )
		return ply.PS2_Inventory:addItem( item )
		:Then( function( )
			KInventory.ITEMS[item.id] = item
			item:OnPurchased( )
			return item
		end )
	end )
	:Fail( function( )
		ply.activeCrate.itemsTaken[ply] = ply.activeCrate.itemsTaken[ply] - 1 -- keep in sync
	end )
end

local function checkContentInstalled(ply)
	if not util.IsValidModel("models/care_package/care_package_new.mdl") then
		if ply:IsAdmin( ) then
			ply:PS2_DisplayError( "[CRITICAL][ADMIN ONLY] Pointshop 2 Airdrops will not work if the Pointshop2 Assets workshop addon isn't installed on the server. Read: bit.ly/airdrops.", 1000 )
		end
	end
end
hook.Add("PS2_PlayerFullyLoaded", "ErrorNotifier", function(ply) 
	timer.Simple(2, function() 
		checkContentInstalled(ply)
	end)
end)