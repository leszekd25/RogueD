module ClientGameView;

import std.stdio;
import utility.ConIO;
import ClientGameInstance;
import Entity;
import utility.Geometry;
import Cell;

enum LogMessageType {SERVER, CLIENT}

struct LogMessage
{
	int ID;
	LogMessageType mtype;
	CharInfo[] msg;

	string ToString()
	{
		char[] s;
		s.length = msg.length;
		for(int i = 0; i < msg.length; i++)
			s[i] = msg[i].ascii_char;
		return s.idup;
	}

	static LogMessage FromString(string s, FColor col = FColor.lightGray)
	{
		LogMessage mss;
		mss.msg.length = s.length;
		for(int i = 0; i < mss.msg.length; i++)
		{
			mss.msg[i].ascii_char = s[i];
			mss.msg[i].attr = cast(ushort)col;
		}
		return mss;
	}
}

class Log  // todo: make static
{
	// for now... dlist will be 100x better
	// todo: dlist
	LogMessage[] messages;
	int max_msg_visible = 8;

	void Write(string msg, FColor col = FColor.lightGray, LogMessageType mt = LogMessageType.CLIENT )
	{
		messages~=LogMessage.FromString(msg, col);
		messages[messages.length-1].mtype = mt;
	}
}

static class ClientGameView
{
	static ClientGameInstance* game = null;
	static Entity* entity_follow = null;
	static Point view_pos = Point(0, 0);
	static Point view_size = Point(60, 25);

	private static Console* con = null;
	static Log gameLog;
	//view sections:
	//[0, 0, 60, 25] main view
	//[60, 60, 40, 32] char info
	//[0, 25, 60, 8] messages
	//total 100x32
	static this()
	{
		con = Console.create();
		gameLog = new Log();
	}

	static ~this()
	{
		con.destroy();
	}

	static void DrawMessages()
	{
		import std.algorithm.comparison;
		int msg_num = min(gameLog.max_msg_visible, gameLog.messages.length)-1;
		int msg_off = max(cast(int)(gameLog.messages.length-gameLog.max_msg_visible), 0);
		for(int i = 0; i <= msg_num; i++)
		{
			LogMessage mss = gameLog.messages[msg_num-i+msg_off];
			(*con).put(0, 25+msg_num-i, mss.msg);
		}
	}

	static void DrawMap()
	{
		Cell[] map = (*game).level.map;
		Point map_size = (*game).level.map_size;
		for(int y = 0; y < 25; y++)
			for(int x = 0; x < 60; x++)
				(*con).put(x, y, map[y*map_size.X+x].glyph.symbol, map[y*map_size.X+x].glyph.color);
		foreach(u; (*game).level.units)
			(*con).put(u.position.X, u.position.Y, u.glyph.symbol, u.glyph.color);
	}

	static void FrameEnd()
	{
		(*con).refresh();
		(*con).clear();
	}

	static void DrawFrame()
	{
		if((*game).level !is null)
			DrawMap();
		DrawMessages();
		FrameEnd();
	}
}