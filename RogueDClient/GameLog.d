module GameLog;

import utility.ConIO: FColor, BColor, CharInfo;
import ClientGameView:ClientGameView;

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

static class Log  // todo: make static
{
	// for now... dlist will be 100x better
	// todo: dlist
	static LogMessage[] messages;
	static int max_msg_visible = 8;

	static void Write(string msg, FColor col = FColor.lightGray, LogMessageType mt = LogMessageType.CLIENT )
	{
		messages~=LogMessage.FromString(msg, col);
		messages[messages.length-1].mtype = mt;
		ClientGameView.RequestLogRedraw();
	}
}