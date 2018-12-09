module Level;

import std.stdio;
import Entity;
import Cell;
import utility.Geometry;
import utility.ConIO: FColor, BColor;

// todo: EVERYTHING by offsets, not by points!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// might be problematic for algorithms though

class Level
{
	int ID;
	ulong step = 0;  //level local time
	int step_multiplier = 100; // base multiplier, the higher it is, the faster the entities relative to baseline
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

		map[10*100+50].glyph = Glyph('#', FColor.lightGray); map[10*100+50].flags = cast(CellFlags)7;
		map[40*100+50].glyph = Glyph('#', FColor.lightGray); map[40*100+50].flags = cast(CellFlags)7;

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

	Point toXY(int i) pure nothrow
	{
		return Point(cast(short)(i%map_size.X), cast(short)(i/map_size.X));
	}

	int toOffset(Point p) pure nothrow
	{
		return p.X+p.Y*map_size.X;
	}

	bool IsValidCell(int i)
	{
		return (i >= 0)&&(i < map.length);
	}

	bool IsValidCell(Point p)
	{
		return (p.X >= 0)&&(p.Y>=0)&&(p.X<map_size.X)&&(p.Y<map_size.Y);
	}

	bool CanMoveToCell(int i)
	{
		return (IsValidCell(i))&&((map[i].flags & CellFlags.blocksMovement) == 0);
	}

	bool CanMoveToCell(Point p)
	{
		return ((IsValidCell(p))&&(map[toOffset(p)].flags & CellFlags.blocksMovement) == 0);
	}

	void UnitMoveTo(ulong u_id, Point pos)
	{
		Unit u = units[u_id];
		u.position = pos;
	}

	bool UnitCanDoAction(ulong u_id)
	{
		Unit u = units[u_id];
		return u.next_action_time <= step;
	}
}