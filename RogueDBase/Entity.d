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
	int base_action_time = 3000;   //100*30 (tps) = 3000
	ulong next_action_time = 0;
	this()
	{
		writeln("Created new unit! ID: ", ID);
	}
	~this()
	{
		writeln("Destroyed unit! ID: ", ID);
	}
}