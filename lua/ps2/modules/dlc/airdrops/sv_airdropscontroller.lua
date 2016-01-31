AirdropsController = class( "AirdropsController" )
AirdropsController:include( BaseController )

function AirdropsController:canDoAction( ply, action )
	local def = Deferred( )

	if action == "addDropSpot" or action == "removeDropSpot" then
    if PermissionInterface.query( ply, 'pointshop2 manageairdrops' ) then
      return Promise.Resolve( )
    end
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
