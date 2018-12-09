module ClientGameView;

import std.stdio;
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
	static Point view_pos = Point(0, 0);
	static Point view_size = Point(60, 25);

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

	static void SetEntityFollow(Entity e)
	{
		entity_follow = e;
	}

	static void RedrawMessages()
	{
		import std.algorithm.comparison;
		int msg_num = min(Log.max_msg_visible, Log.messages.length)-1;
		int msg_off = max(cast(int)(Log.messages.length-Log.max_msg_visible), 0);
		for(int i = 0; i <= msg_num; i++)
		{
			LogMessage mss = Log.messages[msg_num-i+msg_off];
			(*con).put(0, 25+msg_num-i, mss.msg);
		}
	}

	static void RedrawMap()
	{
		Cell[] map = level.map;
		Point map_size = level.map_size;
		if(entity_follow !is null)
			view_pos = entity_follow.position-Point(cast(short)((view_size.X-1)/2), cast(short)((view_size.Y-1)/2));
		if(view_pos.X < 0) view_pos.X = 0;
		if(view_pos.Y < 0) view_pos.Y = 0;
		if(view_pos.X > cast(short)(map_size.X-view_size.X)) view_pos.X = cast(short)(map_size.X-view_size.X);
		if(view_pos.Y > cast(short)(map_size.Y-view_size.Y)) view_pos.Y = cast(short)(map_size.Y-view_size.Y);
		for(int y = 0; y < view_size.Y; y++)
			for(int x = 0; x < view_size.X; x++)
			{
				int m_off = (y+view_pos.Y)*map_size.X+x+view_pos.X;
				(*con).put(x, y, map[m_off].glyph.symbol, map[m_off].glyph.color);
			}
		foreach(u; level.units)
			(*con).put(u.position.X-view_pos.X, u.position.Y-view_pos.Y, u.glyph.symbol, u.glyph.color);
	}

	static void FrameEnd()
	{
		(*con).refresh();
		(*con).clear();
	}

	static void DrawFrame()
	{
		if(level !is null)
			RedrawMap();
		RedrawMessages();
		FrameEnd();
	}
}