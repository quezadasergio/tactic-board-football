class_name TeamData
extends RefCounted

var id: String
var name: String
var short_name: String
var primary: Color
var secondary: Color
var accent: Color

func _init(
	p_id: String,
	p_name: String,
	p_short: String,
	p_primary: Color,
	p_secondary: Color,
	p_accent: Color
) -> void:
	id = p_id
	name = p_name
	short_name = p_short
	primary = p_primary
	secondary = p_secondary
	accent = p_accent


static func fake_roster() -> Array[TeamData]:
	var teams: Array[TeamData] = [
		TeamData.new(
			"norte",
			"Águilas del Norte",
			"NOR",
			Color("1B4F8A"),
			Color("F2C14E"),
			Color("FFFFFF")
		),
		TeamData.new(
			"sur",
			"Tigres del Sur",
			"SUR",
			Color("8B1E1E"),
			Color("E8E8E8"),
			Color("1A1A1A")
		),
		TeamData.new(
			"costa",
			"Delfines de la Costa",
			"COS",
			Color("0E7C7B"),
			Color("F4A261"),
			Color("FFFFFF")
		),
		TeamData.new(
			"sierra",
			"Lobos de la Sierra",
			"SIE",
			Color("3D3A4B"),
			Color("C9A227"),
			Color("F5F5F5")
		),
	]
	return teams
