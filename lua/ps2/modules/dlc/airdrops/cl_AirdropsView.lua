AirdropsView = class( "AirdropsView")
AirdropsView.static.controller = "AirdropsController"
AirdropsView:include( BaseView )

function AirdropsView:addDropSpot( spot )
  return self:controllerTransaction( 'addDropSpot', spot )
end

function AirdropsView:removeDropSpot( spotId )
  return self:controllerTransaction( 'removeDropSpot', spotId )
end
