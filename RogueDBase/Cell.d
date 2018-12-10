module Cell;

import utility.ConIO: FColor, BColor;

enum CellFlags {blocksMovement = 1, blocksVision = 2, blocksProjectiles = 4, discovered = 8, visible = 16};

struct Glyph
{
	char symbol;
	ushort color;

	FColor get_fcolor()
	{
		return cast(FColor)(color & 0xF);
	}

	BColor get_bcolor()
	{
		return cast(BColor)(color >> 4);
	}

	void set_color(FColor f, BColor b = BColor.black)
	{
		color = cast(ushort) (cast(int)f+(((cast(int)b) << 8)));
	}
}

struct Cell
{
	Glyph glyph;
	CellFlags flags = cast(CellFlags)0;
	int movement_cost = 100; // base movement cost is 100, the higher, the slower unit passes through the cell
	int baked_light = 0;  //precomputed at the start of the level, base level of light (not including ambient level light?) (-100 - 100)
	int light_level = 0;  //0-100, 100 is max
}
