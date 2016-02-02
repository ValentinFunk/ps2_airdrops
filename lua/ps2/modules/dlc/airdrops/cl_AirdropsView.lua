AirdropsView = class( "AirdropsView")
AirdropsView.static.controller = "AirdropsController"
AirdropsView:include( BaseView )

function AirdropsView:addDropSpot( spot )
  return self:controllerTransaction( 'addDropSpot', spot )
end

function AirdropsView:removeDropSpot( spotId )
  return self:controllerTransaction( 'removeDropSpot', spotId )
end

-- Called when other players take an item out of currently
-- viewing crate
function AirdropsView:crateItemTaken( crate, index )
  hook.Run( "PS2_CrateItemTaken", crate, index )
end

function AirdropsView:supplyCrateTakeItem( index )
  return self:controllerTransaction( "supplyCrateTakeItem", index )
end

function AirdropsView:openCrate( crate, contents )
  if IsValid( self.contentsGui ) then
    self.contentsGui:Remove( )
  end

  self.contentsGui = vgui.Create( "DAirdropCrateContents" )
  self.contentsGui:SetCrate( crate )
  self.contentsGui:SetContents( contents )
  self.contentsGui:MakePopup( )
  self.contentsGui:Center( )
end
