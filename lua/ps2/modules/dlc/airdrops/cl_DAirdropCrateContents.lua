local PANEL = {}

function PANEL:Init( )
  self:SetSkin( Pointshop2.Config.DermaSkin )
  self:SetSize( 300, 500 )

  self:SetTitle( "Airdrop Crate" )

  self.info = vgui.Create( "DLabel", self )
  self.info:Dock( TOP )
  self.info:SetColor( self:GetSkin( ).Highlight )
  self.info._Paint = self.info.Paint or function( ) end
  self.info:SetContentAlignment( 5 )
  self.info:DockMargin( 0, 5, 5, 5 )
  function self.info:Paint( w, h )
    self._Paint( self, w, h )
    derma.SkinHook( "Paint", "InnerPanel", self, w, h )
  end
  self.info:SetFont( self:GetSkin( ).TextFont )

  self.scroll = vgui.Create( "DScrollPanel", self )
  self.scroll:Dock( FILL )

  self.itemPanels = {}
end

function PANEL:SetCrate( crate )
  self.crate = crate
end

function PANEL:Think( )
  if not IsValid( self.crate ) then
    return self:Remove( )
  end

  if self.crate:GetPos( ):Distance( LocalPlayer( ):GetPos( ) ) > Pointshop2.Airdrops.MAX_USE_DISTANCE then
    return self:Remove( )
  end

  self.amountLeft = Pointshop2.GetSetting( "Pointshop 2 DLC", "AirdropCrateSettings.MaxItemsPerPlayer" )
  if IsValid( self.crate ) and self.crate.itemsTaken then
    self.amountLeft = math.max( 0, self.amountLeft - self.crate.itemsTaken ) --  amountLeft is >= 0
  end
  if self.amountLeft == 0 then
    self.info:SetText( "You have taken the maxium amount of items" )
  else
    self.info:SetText( "You can take " .. self.amountLeft .. " more items" )
  end
end

// Bit larger function so taken into seperate function. PaintOver of the item rows
local function itemPanelPaintOver( self, w, h )
  local text, textcol = "", color_white
  local drawOverlay = function( )
    local col = table.Copy( self:GetSkin().InnerPanel )
    col.a = 240
    surface.SetDrawColor( col )
    surface.DrawRect( 0, 0, w, h )
  end

  if self.loading then
    text = "Loading"
    textcol = self:GetSkin().Colours.Label.Dark
    drawOverlay( )
  elseif self.taken then
    text = "Already taken"
    textcol = self:GetSkin().Colours.Label.Dark
    drawOverlay( )
  elseif self.claimed then
    text = "Claimed"
    textcol = Color( 0, 255, 0 )
    drawOverlay( )
  elseif self.error then
    text = "Error"
    textcol = self:GetSkin().Colours.Label.Dark
    drawOverlay( )
  elseif self.Hovered or self:IsChildHovered( 6 ) then
    if self.airdropsGui.amountLeft and self.airdropsGui.amountLeft == 0 then
      text = "Limit Reached"
      textcol = self:GetSkin().Colours.Label.Dark
      drawOverlay( )
    else
      local col = table.Copy( self:GetSkin().InnerPanel )
      col.a = 150
      surface.SetDrawColor( col )
      surface.DrawRect( 0, 0, w, h )

      local col = table.Copy( self:GetSkin().Colours.Label.Highlight )
      col.a = 150
      surface.SetDrawColor( col )

      surface.DrawRect( 0, 0, w, h )
      text = "Take"
    end
  end

  draw.SimpleText( text, self:GetSkin( ).BigTitleFont, w / 2, h / 2, textcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end


function PANEL:SetContents( contents )
  local airdropsGui = self
  for k, item in pairs( contents ) do
		local pnl = vgui.Create( "DButton", self.scroll )
		pnl:SetTall( 75 )
		pnl:Dock( TOP )
		pnl:DockPadding( 5, 5, 5, 5 )
		pnl:SetText( "" )
		pnl:DockMargin( 0, 5, 5, 5 )
    self.itemPanels[k] = item
    pnl.airdropsGui = airdropsGui

		pnl.icon = item:getNewInventoryIcon( )
		pnl.icon:SetSize( 64, 64 )
		pnl.icon:Dock( LEFT )
    pnl.icon:SetParent( pnl )
    pnl.icon:SetMouseInputEnabled( false )

		pnl.title = vgui.Create( "DLabel", pnl )
		pnl.title:Dock( TOP )
		pnl.title:DockMargin( 5, 0, 5, 0 )
		pnl.title:SetFont( self:GetSkin().SmallTitleFont )
		pnl.title:SetColor( Pointshop2.RarityColorMap[item._airdropChance] )
		pnl.title:SetText( item:GetPrintName( ) )
		pnl.title:SizeToContents( )

		pnl.class = vgui.Create( "DMultilineLabel", pnl )
		pnl.class:Dock( TOP )
		pnl.class:DockMargin( 5, 0, 5, 0 )
		pnl.class:SetText( item:GetDescription( ) )
    pnl.class:SetMouseInputEnabled( false )

		function pnl:DoClick( )
      if self.claimed or self.taken or airdropsGui.amountLeft == 0 then
        return
      end

      self:SetDisabled( true )
      self.loading = true

      airdropsGui.crate.itemsTaken = ( airdropsGui.crate.itemsTaken or 0 ) + 1
      AirdropsView:getInstance( ):supplyCrateTakeItem( k )
      :Done( function( item )
        Pointshop2View:getInstance( ):displayItemAddedNotify( item )
        self.claimed = true
      end )
      :Fail( function( err )
        if err == "Already Taken" then
          self:SetTaken( )
          return
        end
        Pointshop2View:getInstance( ):displayError( "Error claming item: " .. tostring( err ) )
        self.error = true
        airdropsGui.crate.itemsTaken = airdropsGui.crate.itemsTaken - 1 -- undo counter
      end )
      :Always( function( )
        self.loading = false
      end )
		end

    function pnl:PerformLayout( )
      DButton.PerformLayout( self )
      self:SizeToChildren( false, true )
      self.icon:SetMouseInputEnabled( false )
    end

    function pnl:SetTaken( )
      self:SetDisabled( true )
      self.taken = true
      self.error = false
    end

    pnl.PaintOver = itemPanelPaintOver

		Derma_Hook( pnl, "Paint", "Paint", "InnerPanel" )

    if item._airdropsTaken then
      pnl:SetTaken( )
    end
	end

  hook.Add( "PS2_CrateItemTaken", self, self.CrateItemTaken )
end

function PANEL:CrateItemTaken( crate, index )
  if crate == self.crate and self.itemPanels[index] then
    self.itemPanels[index]:SetTaken( )
  end
end

vgui.Register( "DAirdropCrateContents", PANEL, "DFrame" )
