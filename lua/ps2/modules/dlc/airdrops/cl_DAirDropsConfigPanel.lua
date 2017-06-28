local PANEL = {}
local GLib = LibK.GLib

function PANEL:Init( )
  self.mod = Pointshop2.GetModule( "Pointshop 2 DLC" )

  self:SetSkin( Pointshop2.Config.DermaSkin )
  self:DockPadding( 10, 0, 10, 10 )

  self.loadingNotifier = vgui.Create( "DLoadingNotifier", self )
  self.loadingNotifier:Dock( TOP )

  local top = vgui.Create( "DSizeToContents", self )
  top:Dock( TOP )
  top:SetSizeX( false )
  top:SetTall( 390 )
  top:DockMargin( 0, 5, 0, 0 )

  local left = vgui.Create( "DPanel", top )
  left:Dock( LEFT )
  left:SetWide( 300 )
  left:DockMargin( 0, 0, 10, 0 )
  left.Paint = function( ) end

  self.infoPanel = vgui.Create( "DInfoPanel", left )
  self.infoPanel:Dock( TOP )
  self.infoPanel:SetSmall( true )
  self.infoPanel:SetInfo( "About Airdrops",
[[The air drops system works like this:
- Every few minutes a random spot is chosen from Airdrop Locations list. A helicopter delivers a physical crate.
- You configure the amount of items in a crate. The crate always contains exactly that amount of items. The items are picked by random using the configured chances.

You can only add/edit locations for the map that you are currently playing. If no locations are set up, no crates are dropped.
]] )
  self.infoPanel:DockMargin( 0, 5, 0, 0 )

  local label1 = vgui.Create( "DLabel", left )
  label1:SetText( "Airdrop Locations (this map)" )
  label1:SetFont( self:GetSkin( ).TabFont )
  label1:SizeToContents( )
  label1:SetColor( color_white )
  label1:Dock( TOP )
  label1:DockMargin( 0, 0, 0, 5 )

  local locationsContainer = vgui.Create( "DPanel", left )
  locationsContainer:Dock( FILL )
  locationsContainer:DockPadding( 5, 5, 5, 5 )
  Derma_Hook( locationsContainer, "Paint", "Paint", "InnerPanel" )

  local spotsScroll = vgui.Create( "DScrollPanel", locationsContainer )
  spotsScroll:Dock( TOP )
  spotsScroll:SetWide( 300 )
  spotsScroll:SetTall( 110 )
  Derma_Hook( spotsScroll, "Paint", "Paint", "InnerPanelBright" )

  self.spotsTable = vgui.Create( "DListView", spotsScroll )
  self.spotsTable:Dock( TOP )
  self.spotsTable:AddColumn( "Name" )
  self.spotsTable:AddColumn( "Actions" )
  self.spotsTable:SetDataHeight( 30 )
  self.spotsTable:SetTall( 300 )
  self.spotsTable.PerformLayout = function( self )
    DListView.PerformLayout( self )
    self:SizeToContents( )
    self:SetTall( math.min( self:GetTall( ) , 110 ) )
  end
  hook.Add( "PS2_Airdrops_NewPosition", self, self.OnNewAirdropPosition )


  locationsContainer.bottomBar = vgui.Create( "DPanel", locationsContainer )
  locationsContainer.bottomBar:Dock( BOTTOM )
  locationsContainer.bottomBar:DockMargin( 0, 5, 0, 0 )
  locationsContainer.bottomBar.Paint = function() end
  locationsContainer.bottomBar:SetTall( 25 )

  locationsContainer.bottomBar.addBtn = vgui.Create( "DButton", locationsContainer.bottomBar )
  locationsContainer.bottomBar.addBtn:SetImage( "pointshop2/plus24.png" )
  locationsContainer.bottomBar.addBtn.m_Image:SetSize( 16, 16 )
  locationsContainer.bottomBar.addBtn:SetText( "Add" )
  locationsContainer.bottomBar.addBtn:Dock( LEFT )
  locationsContainer.bottomBar.addBtn:SetSize( 100, 25 )
  function locationsContainer.bottomBar.addBtn.DoClick( )
    self:StartHelospotPlacement( )
  end

  local right = vgui.Create( "DPanel", top )
  right:Dock( FILL )
  right.Paint = function( ) end

  local label1 = vgui.Create( "DLabel", right )
  label1:SetText( "Airdrop Settings" )
  label1:SetFont( self:GetSkin( ).TabFont )
  label1:SizeToContents( )
  label1:SetColor( color_white )
  label1:Dock( TOP )
  label1:DockMargin( 0, 0, 0, 0 )

  self.actualSettings = vgui.Create( "DSettingsPanel", right )
  self.actualSettings:Dock( FILL )
  self.actualSettings:AutoAddSettingsTable( {
    AirDropsSettings = Pointshop2.GetModule( "Pointshop 2 DLC" ).Settings.Server.AirDropsSettings,
    AirdropCrateSettings = Pointshop2.GetModule( "Pointshop 2 DLC" ).Settings.Shared.AirdropCrateSettings,
  } )
  self.actualSettings:DockMargin( 0, 0, 0, 5 )
  self.actualSettings:SetWide( 250 )
  self.actualSettings.saveBtn = vgui.Create( "DButton", self.actualSettings )
	self.actualSettings.saveBtn:SetImage( "pointshop2/floppy1.png" )
	self.actualSettings.saveBtn.m_Image:SetSize( 16, 16 )
	self.actualSettings.saveBtn:SetText( "Save" )
	self.actualSettings.saveBtn:Dock( TOP )
	self.actualSettings.saveBtn:SetSize( 100, 28 )
  self.actualSettings.saveBtn:DockMargin( 0, 0, 0, 0 )
	function self.actualSettings.saveBtn.DoClick( )
		local promise = Pointshop2View:getInstance( ):saveSettings( self.mod, "Shared", self.actualSettings.settings )
    self:DisplayPromiseStatus( promise )
	end

  local label1 = vgui.Create( "DLabel", self )
  label1:SetText( "Airdrop Item Chances / Crate Contents" )
  label1:SetFont( self:GetSkin( ).TabFont )
  label1:SizeToContents( )
  label1:SetColor( color_white )
  label1:Dock( TOP )
  label1:DockMargin( 0, 5, 0, 5 )

  self.itemsTable = vgui.Create( "DItemChanceTable", self )
	self.itemsTable:Dock( FILL )
	self.itemsTable:DockPadding( 5, 5, 5, 5 )
	Derma_Hook( self.itemsTable, "Paint", "Paint", "InnerPanel" )
  self.itemsTable.bottomBar:SetTall( 25 )

	self.itemsTable.bottomBar.saveBtn = vgui.Create( "DButton", self.itemsTable.bottomBar )
	self.itemsTable.bottomBar.saveBtn:SetImage( "pointshop2/floppy1.png" )
	self.itemsTable.bottomBar.saveBtn.m_Image:SetSize( 16, 16 )
	self.itemsTable.bottomBar.saveBtn:SetText( "Save" )
	self.itemsTable.bottomBar.saveBtn:Dock( LEFT )
	self.itemsTable.bottomBar.saveBtn:SetSize( 100, 40 )
  self.itemsTable.bottomBar.saveBtn:DockMargin( 5, 0, 0, 0 )
	function self.itemsTable.bottomBar.saveBtn.DoClick( )
    local settings = {
      ["AirDropsTableSettings.DropsData"] = self.itemsTable:GetSaveData( )
    }

  	local promise = Pointshop2View:getInstance( ):saveSettings( self.mod, "Server", settings )
    self:DisplayPromiseStatus( promise )
	end

  hook.Add( "PS2_OnSettingsUpdate", self, self.RequestSettings )
  self:RequestSettings( )
end

function PANEL:AddSpot( positionData )
  local line = self.spotsTable:AddLine( positionData.name )
  line.posData = positionData
  line.Columns[2] = vgui.Create( "DPanel", line )
  line.Columns[2].Paint = function( ) end
  line.Columns[2]:DockPadding( 2, 2, 2, 2 )

  local remove = vgui.Create( "DButton", line.Columns[2] )
  remove:SetText( "Remove" )
  function remove.DoClick( )
    local promise = AirdropsView:getInstance( ):removeDropSpot( line.posData.id )
    promise:Done( function( )
      self.spotsTable:RemoveLine( line:GetID( ) )
    end )
    self:DisplayPromiseStatus( promise )
  end
  remove:Dock( FILL )

  if not positionData.id then
    local promise = AirdropsView:getInstance( ):addDropSpot( positionData )
    promise:Done( function( id )
      line.posData.id = id
    end)
    self:DisplayPromiseStatus( promise )
  end
end

function PANEL:OnNewAirdropPosition( positionData )
  self:AddSpot( positionData )

  Pointshop2.Menu:SetVisible( true )
  gui.EnableScreenClicker( true )
end

function PANEL:StartHelospotPlacement( )
  net.Start( "AirDrops_StartPlacement" )
  net.SendToServer( )

  Pointshop2.Menu:SetVisible( false )
  gui.EnableScreenClicker( false )
end

function PANEL:OnActivate( )
  self:RequestSettings( )
end

-- Notify the panel that a promise is loading, shows loading indicator automatically
function PANEL:DisplayPromiseStatus( promise )
  self.loadingNotifier:Expand( )
  self:SetDisabled( true )
  promise:Done( function( )
    if IsValid(self) then
      self:SetDisabled( false )
    end
  end )
  promise:Fail( function( err )
    Pointshop2View:getInstance( ):displayError( err )
  end )
  :Always( function( )
    if IsValid(self) then
      self.loadingNotifier:Collapse( )
    end
  end )
end

-- Request Settings from Server
function PANEL:RequestSettings( )
  local promise = Pointshop2.RequestSettings( "Pointshop 2 DLC" )
  :Done( function( data )
    if IsValid(self) then
      self:SetData( data )
    end
  end )
  self:DisplayPromiseStatus( promise )
end

-- Populate controls with settings data
function PANEL:SetData( data )
  self.actualSettings:SetData( data )
  self.itemsTable.itemTable:Clear( )
	self.itemsTable:LoadSaveData( data["AirDropsTableSettings.DropsData"] )
  self.spotsTable:Clear( )
  for k, v in pairs( data["CrateSpotSettings.CrateSpots"] ) do
    self:AddSpot( v )
  end
end

function PANEL:Paint( )
end

vgui.Register( "DAirDropsConfigPanel", PANEL, "DPanel" )

Pointshop2:AddManagementPanel( "Airdrops", "pointshop2/parachuting.png", "DAirDropsConfigPanel", function( )
	return PermissionInterface.query( LocalPlayer(), "pointshop2 manageairdrops" )
end )
