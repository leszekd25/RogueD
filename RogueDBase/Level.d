module Level;

import std.stdio;
import Entity;
import Cell;
import utility.Geometry;
import utility.ConIO: FColor, BColor;

class Level
{
	int ID;
	ulong step = 0;  //level local time
	short delay_multiplier = 100; // base multiplier, the higher it is, the slower the entities relative to baseline
	Unit[ulong] units;
	Point map_size;
	Cell[] map;    // change to 2D
	Point starting_point;

	void Test()
	{
		map_size = Point(100, 50);
		int wh = map_size.X*map_size.Y;
		map.length = wh;
		for(int i = 0; i < wh; i++)
			map[i].glyph = Glyph('.', FColor.lightGray);
		starting_point = Point(10, 10);
	}

	/// add unit to the level
	void AddUnitToLevel(Point position, ref ulong u_id)
	{
		units[u_id] = new Unit();
		units[u_id].ID = u_id;
		units[u_id].levelID = ID;
		units[u_id].position = position;

		u_id++;
	}

	/// remove unit from this level
	void RemoveUnitFromLevel(ulong u_id)
	{
		Unit* u = (u_id in units);
		assert(u !is null, "Error: Can't remove unit from the level: No unit found!");

		//remove unit from the map
		units[u_id].destroy();
		units.remove(u_id);
	}
}