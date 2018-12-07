module Messages;

import std.bitmanip;
import std.stdio;
import utility.Geometry;

enum MessageType
{
	DISCONNECT, EXIT, PING,
	SPAWN_UNIT, 
	LOG_IN, LOG_OUT, LOG_OUT_OK, LOG_OUT_FAILED, LOG_IN_FAILED, LOG_IN_OK,
	REGISTER, REGISTER_FAILED, REGISTER_OK,
	ERROR
}
/*
pattern:
-connect
-confirm connect
...
-log in
-log in ok/failed,
...
do stuff
ping meanwhile
if(log out sent)
   log out
   log out ok/failed
if(sudden disconnect)
   exit if possible
...
log out
log out ok/failed
...
exit
confirm disconnect


*/

class Message  // base type message
{
	MessageType msg_t;

	this()
	{

	}

	this(MessageType mt)
	{
		msg_t = mt;
	}
}

class SpawnUnitMessage: Message
{
	Point position;
	ulong server_unitID;
	// creature data
	this()
	{

	}

	this(Point p, ulong sid)
	{
		msg_t = MessageType.SPAWN_UNIT;
		position = p;
		server_unitID = sid;
	}
}

// !!! unencrypted!
class LogInMessage: Message
{
	string name;
	string password;

	this()
	{

	}

	this(string n, string p)
	{
		msg_t = MessageType.LOG_IN;
		name = n;
		password = p;
	}
}

class ErrorMessage: Message
{
	string error;

	this(string e)
	{
		msg_t = MessageType.ERROR;
		error = e;
	}
}

Message BufferToMessage(ubyte[] buf)
{
	string data_to_str(ubyte[] b)
	{
		int s_len = cast(int)(buf.read!ushort());
		char[] s_str;  s_str.length = s_len;
		for(int i = 0; i < s_len; i++)
			s_str[i] = buf.read!char();
		return s_str.idup;
	}
	//writeln(buf.length);
	Message msg;
	MessageType msg_t = cast(MessageType)(buf.read!int());
	switch(msg_t)
	{
		case MessageType.LOG_IN:
		case MessageType.REGISTER:
			string nm = data_to_str(buf);
			string ps = data_to_str(buf);
			msg = cast(Message)(new LogInMessage(nm, ps));
			msg.Message.msg_t = msg_t;
			break;
		case MessageType.ERROR:
			msg_t = buf.read!MessageType();
			string er = data_to_str(buf);
			msg = cast(Message)(new ErrorMessage(er));
			msg.Message.msg_t = msg_t;
			break;
		case MessageType.SPAWN_UNIT:
			msg_t = buf.read!MessageType();
			short x = buf.read!short();
			short y = buf.read!short();
			ulong sid = buf.read!ulong();
			msg = cast(Message)(new SpawnUnitMessage(Point(x, y), sid));
			msg.Message.msg_t = msg_t;
			break;
		default:
			msg = new Message(msg_t);
			break;
	}
	(msg).msg_t = msg_t;
	return msg;
}

ubyte[] MessageToBuffer(Message msg)
{
	int str_to_data(string s, ubyte[] b, int pos)
	{
		int l = s.length;
		b.write!ushort(cast(ushort)l, pos);
		for(int i = 0; i < l; i++)
			b.write!char(s[i], 2+i+pos);
		return 2+pos+l;
	}

	ubyte[] buf;
	int next_pos = 0;
	switch((msg).msg_t)
	{
		case MessageType.SPAWN_UNIT:
			SpawnUnitMessage msg_ok = cast(SpawnUnitMessage)msg;
			buf.length = 16;

			buf.write!MessageType((msg_ok).msg_t, 0);
			buf.write!short((msg_ok).position.X, 4);
			buf.write!short((msg_ok).position.Y, 6);
			buf.write!ulong((msg_ok).server_unitID, 8);
			break;
		case MessageType.LOG_IN:
		case MessageType.REGISTER:
			LogInMessage msg_ok = cast(LogInMessage)msg;
			buf.length = 4+(msg_ok).name.length+(msg_ok).password.length+4;   // move to msg method?
			buf.write!MessageType((msg_ok).msg_t, 0);
			next_pos = str_to_data((msg_ok).name, buf, next_pos+4);
			next_pos = str_to_data((msg_ok).password, buf, next_pos);
			break;
		case MessageType.ERROR:
			ErrorMessage msg_ok = cast(ErrorMessage)msg;
			buf.length = 4+(msg_ok).error.length+2;   // move to msg method?

			buf.write!MessageType((msg_ok).Message.msg_t, 0);
			next_pos = str_to_data((msg_ok).error, buf, next_pos+4);
			break;
		default:
			buf.length = 4;
			buf.write!MessageType((msg).msg_t, 0);
			break;
	}
	msg.destroy();
	return buf;
}