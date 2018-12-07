module Entity;

import std.stdio;
import Cell: Glyph;
import utility.Geometry: Point;

class Entity
{
	ulong ID;
	int levelID;
	Glyph glyph;
	Point position;
}

class Unit: Entity
{
	int base_speed = 100;   // base action speed, the higher, the better
	this()
	{
		writeln("Created new unit! ID: ", ID);
	}
	~this()
	{
		writeln("Destroyed unit! ID: ", ID);
	}
}