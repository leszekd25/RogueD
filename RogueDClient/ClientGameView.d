module ClientGameView;

import std.stdio;
import Connections:Queue;
import utility.ConIO;
import Level;
import GameLog;
import Entity;
import utility.Geometry;
import Cell;

static class ClientGameView
{
	static Level level = null;
	static Entity entity_follow = null;
	static Point last_entity_pos = Point(0, 0);
	static Point view_pos = Point(0, 0);
	static Point view_size = Point(60, 25);
	static bool map_redraw = true;
	static bool messages_redraw = true;
	static Queue!Entity redraw_entities;
	
	static this()
	{
		redraw_entities = new Queue!Entity();
	}

	private static Console* con = null;
	//view sections:
	//[0, 0, 60, 25] main view
	//[60, 60, 40, 32] char info
	//[0, 25, 60, 8] messages
	//total 100x32
	static this()
	{
		con = Console.create();
	}

	static ~this()
	{
		con.destroy();
	}

	static bool IsPointInView(Point p)
	{
		return (p.X >= view_pos.X)&&(p.X < view_pos.X+view_size.X)&&(p.Y >= view_pos.Y)&&(p.Y < view_pos.Y+view_size.Y);
	}

	static void RequestMapRedraw()
	{
		map_redraw = true;
	}

	static void RequestLogRedraw()
	{
		messages_redraw = true;
	}

	static void EntityRedraw(Entity e)
	{
		redraw_entities.push(e);
	}

	static void SetEntityFollow(Entity e)
	{
		entity_follow = e;
		last_entity_pos = e.position;
	}

	static void UpdateEntityState()
	{
		if(entity_follow !is null)
		{
			if(entity_follow.position != last_entity_pos)
			{
				last_entity_pos = entity_follow.position;
				Point map_size = level.map_size;
				Point new_view_pos = entity_follow.position-Point(cast(short)((view_size.X-1)/2), cast(short)((view_size.Y-1)/2));
				if(new_view_pos.X < 0) new_view_pos.X = 0;
				if(new_view_pos.Y < 0) new_view_pos.Y = 0;
				if(new_view_pos.X > cast(short)(map_size.X-view_size.X)) new_view_pos.X = cast(short)(map_size.X-view_size.X);
				if(new_view_pos.Y > cast(short)(map_size.Y-view_size.Y)) new_view_pos.Y = cast(short)(map_size.Y-view_size.Y);
				if(new_view_pos != view_pos)
				{
					map_redraw = true;
					view_pos = new_view_pos;
				}
			}
		}

		if(level !is null)
		{
			Cell[] map = level.map;
			Point map_size = level.map_size;
			while(!(redraw_entities.empty()))
			{
				Entity e = redraw_entities.pop();
				if(IsPointInView(e.previous_position))
				{
					int m_off = (e.previous_position.Y)*map_size.X+e.previous_position.X;
					(*con).put_instant(e.previous_position.X-view_pos.X, e.previous_position.Y-view_pos.Y, map[m_off].glyph.symbol, map[m_off].glyph.color);
				}
				if(IsPointInView(e.position))
				{
					int m_off = (e.position.Y)*map_size.X+e.position.X;
					(*con).put_instant(e.position.X-view_pos.X, e.position.Y-view_pos.Y, e.glyph.symbol, e.glyph.color);
				}
			}
		}
	}

	static void RedrawMessages()
	{
		(*con).clear_region(cast(short)0, view_size.Y, view_size.X, cast(short)(Log.max_msg_visible));
		import std.algorithm.comparison;
		int msg_num = min(Log.max_msg_visible, Log.messages.length)-1;
		int msg_off = max(cast(int)(Log.messages.length-Log.max_msg_visible), 0);
		for(int i = 0; i <= msg_num; i++)
		{
			LogMessage mss = Log.messages[msg_num-i+msg_off];
			(*con).put(0, view_size.Y+msg_num-i, mss.msg);
		}

		//(*con).refresh();
		(*con).refresh_region(cast(short)0, view_size.Y, view_size.X, cast(short)(Log.max_msg_visible));
	}

	static void RedrawMap()
	{
		(*con).clear_region(0, 0, view_size.X, view_size.Y);
		Cell[] map = level.map;
		Point map_size = level.map_size;
		for(int y = 0; y < view_size.Y; y++)
			for(int x = 0; x < view_size.X; x++)
			{
				int m_off = (y+view_pos.Y)*map_size.X+x+view_pos.X;
				(*con).put(x, y, map[m_off].glyph.symbol, map[m_off].glyph.color);
			}
		foreach(u; level.units)
			(*con).put(u.position.X-view_pos.X, u.position.Y-view_pos.Y, u.glyph.symbol, u.glyph.color);

		//(*con).refresh();
		(*con).refresh_region(0, 0, view_size.X, view_size.Y);
	}

	static void FrameEnd()
	{
		(*con).refresh();
		(*con).clear();
	}

	static void DrawFrame()
	{
		if(map_redraw)
		{
			if(level !is null)
			{
				RedrawMap();
				map_redraw = false;
			}
		}
		if(messages_redraw)
		{
			RedrawMessages();
			messages_redraw = false;
		}
		//FrameEnd();
	}
}