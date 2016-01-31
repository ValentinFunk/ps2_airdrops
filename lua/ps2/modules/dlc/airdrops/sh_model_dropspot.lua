Pointshop2.AirdropDropSpot = class( "Pointshop2.AirdropDropSpot" )
local AirdropDropSpot = Pointshop2.AirdropDropSpot

AirdropDropSpot.static.DB = "Pointshop2"

AirdropDropSpot.static.model = {
	tableName = "ps2_airdropspots",
	fields = {
		map = "string",
		pos = "luadata",
		ang = "luadata",
		height = "int",
    name = "string"
	}
}

AirdropDropSpot:include( DatabaseModel )
