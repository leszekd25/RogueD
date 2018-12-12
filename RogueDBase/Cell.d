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
	int emit_light;
	int movement_cost;
	this()
	{
		glyph = Glyph('.', 0);
		flags = cast(CellFlags)0;
		assert(!flags);
		emit_light = 0;
		movement_cost = 100;
	}
	void ParseCommands(ref string[][int] commands)
	{
		import std.conv:to;
	
		for(int i =  0; i < commands.length; i++)
		{
			string[] command = commands[i];
			switch(command[0])
			{
				case "symbol":
					glyph.symbol = command[1][0];
					break;
				case "color":
					glyph.color = cast(ushort)(to!FColor(command[1]));
					break;
				case "flags":
					for(int j = 1; j < command.length; j++)
						flags |= to!CellFlags(command[j]);
					break;
				case "emit_light":
					emit_light = to!int(command[1]);
					break;
				case "movement_cost":
					movement_cost = to!int(command[1]);
					break;
				default:
					break;
			}
		}

	}
}