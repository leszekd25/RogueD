module Level;

import std.stdio;
import Entity;
import Cell;
import Light;
import utility.Geometry;
import utility.ConIO: FColor, BColor;

// todo: EVERYTHING by offsets, not by points!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// might be problematic for algorithms though

class Level
{
	int ID;
	ulong step = 0;  //level local time
	int step_multiplier = 100; // base multiplier, the higher it is, the faster the entities relative to baseline
	int ambient_light = 100;  //-100 to 100
	Unit[ulong] units;
	Point map_size;
	Cell[] map;    // change to 2D
	Light[int] lights;

	Point starting_point;

	void Test()
	{
		map_size = Point(100, 50);
		int wh = map_size.X*map_size.Y;
		map.length = wh;
		for(int i = 0; i < wh; i++)
		{
			map[i].glyph = Glyph('.', FColor.lightGray);
			ComputeLightPowerAtCell(toPoint(i));
		}
			

		map[10*100+50].glyph = Glyph('#', FColor.lightGray); map[10*100+50].flags = cast(CellFlags)7;
		map[40*100+50].glyph = Glyph('#', FColor.lightGray); map[40*100+50].flags = cast(CellFlags)7;

		starting_point = Point(10, 10);
	}

	// cells

	Point toPoint(int i) pure nothrow
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

	// lighting

	void ComputeLightPowerAtCell(Point p)
	{
		if(!IsValidCell(p))
			return;

		int offset = toOffset(p);
		int base = ambient_light+map[offset].baked_light;
		foreach(light; lights.values)
		{
			if(!(light.is_on))
				continue;
			int d = p.dist(light.position);
			if(d > light.range)
				continue;
			base += light.get_strength(d);
		}
		if(base < 0)
			base = 0;
		if(base>100)
			base = 100;
		map[offset].light_level = base;
	}

	void RegionUpdateLight(short t, short l, short b, short r)
	{
		for(short y = t; y <= b; y++)
			for(short x = l; x <= r; x++)
			{
				ComputeLightPowerAtCell(Point(x, y));
			}
	}

	void LightUpdate(Light l)
	{
		RegionUpdateLight(cast(short)(l.position.X-l.range),
						  cast(short)(l.position.Y-l.range),
						  cast(short)(l.position.X+l.range),
						  cast(short)(l.position.Y+l.range));
	}

	void LightMove(int l_id, Point npos)
	{
		Light l = lights[l_id];
		if(l.is_on)
		{
			l.is_on = false;
			LightUpdate(l);
			l.position = npos;
			l.is_on = true;
			LightUpdate(l);
		}
		else
		{
			l.position = npos;
		}
	}

	int LightCreate(Point p, int r, int i = 100, int o = 0, bool on = true)
	{
		Light l = new Light(p, r, i, o);
		lights[l.ID] = l;
		l.is_on = on;
		if(l.is_on)
			LightUpdate(l);
		return l.ID;
	}

	void LightDestroy(int l_id)
	{
		Light l = lights[l_id];
		if(l.is_on)
		{
			l.is_on = false;
			LightUpdate(l);
}
		lights.remove(l_id);
		l.destroy();
	}

	// units

	/// add unit to the level
	void AddUnitToLevel(Point position, ref ulong u_id)
	{
		units[u_id] = new Unit();
		units[u_id].ID = u_id;
		units[u_id].levelID = ID;
		units[u_id].position = position;
		units[u_id].previous_position = position;

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

	void UnitMoveTo(ulong u_id, Point pos)
	{
		Unit u = units[u_id];
		u.previous_position = u.position;
		u.position = pos;
	}

	bool UnitCanDoAction(ulong u_id)
	{
		Unit u = units[u_id];
		return u.next_action_time <= step;
	}
}