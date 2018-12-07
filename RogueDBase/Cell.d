module Cell;

import utility.ConIO: FColor, BColor;

enum CellFlags {blocksMovement = 1, blocksVision = 2, blocksProjectiles = 4, discovered = 8};

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
}

struct Cell
{
	Glyph glyph;
	CellFlags flags = cast(CellFlags)0;
	int movement_cost = 100; // base movement cost is 100, the higher, the slower unit passes through the cell
}
