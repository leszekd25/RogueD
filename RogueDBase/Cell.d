module Cell;

import utility.ConIO: FColor, BColor;
import TemplateDatabase;
import utility.TemplateReader;

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
	int baked_light = 0;  //precomputed at the start of the level, base level of light (not including ambient level light?)
	int emit_light = 0;   //cell's inner light (for example, lava glows)
	int light_level = 0;  //0-100, 100 is max, read only - refer to lights on level
}

class CellTemplate:DataTemplate
{
	Glyph glyph;
	CellFlags flags;
	int movement_cost;
	int emit_light;
	override void ReadTemplate(TemplateReader tr)
	{
		import std.conv:parse;

		char chr = tr.EntryGetParameter("symbol")[0][0];
		ushort col = cast(ushort)(parse!FColor(tr.EntryGetParameter("color")[0]));
		glyph = Glyph();
		glyph.symbol = chr; glyph.color = col;
		flags = cast(CellFlags)0;
		emit_light = 0;
		movement_cost = 100;
		if(tr.EntryHasParameter("flags"))
			foreach(s; tr.EntryGetParameter("flags"))
				flags |= parse!CellFlags(s);
		if(tr.EntryHasParameter("emit_light"))
			emit_light = parse!int(tr.EntryGetParameter("emit_light")[0]);
		if(tr.EntryHasParameter("movement_cost"))
			emit_light = parse!int(tr.EntryGetParameter("movement_cost")[0]);

	}
}