module Messages;

import std.bitmanip;
import std.stdio;
import utility.Geometry;
import  Cell;
import Light;
import Entity;

enum MessageType
{
	DISCONNECT, EXIT, PING,
	LOG_IN, LOG_OUT, LOG_OUT_OK, LOG_OUT_FAILED, LOG_IN_FAILED, LOG_IN_OK,
	READY_TO_LOAD_LEVEL, LEVEL_DATA,
	REGISTER, REGISTER_FAILED, REGISTER_OK,
	MOVE_ACTION, ATTACK_ACTION, SPELL_ACTION,
	SPAWN_UNIT, UNIT_MOVED, UNIT_DAMAGED, UNIT_HEALED, UNIT_SPAWN_EFFECT, UNIT_DESPAWN_EFFECT,
	LOCAL_MESSAGE, PARTY_MESSAGE, PLAYER_MESSAGE, SERVER_MESSAGE,
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
	//todo: replace with Unit
	Point position;
	ulong server_unitID;
	// creature data

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

class LevelDataMessage: Message
{
	import Level;
	Level data;
	ulong player_unitID;

	this(Level l, ulong pu_id)
	{
		msg_t = MessageType.LEVEL_DATA;
		data = l;
		player_unitID = pu_id;
	}
}


class MoveActionMessage: Message
{
	Direction dir;

	this(Direction d)
	{
		msg_t = MessageType.MOVE_ACTION;
		dir = d;
	}
}

class UnitMovedMessage: Message
{
	ulong u_id;
	Point pos;

	this(ulong u, Point p)
	{
		u_id = u;
		pos = p;
		msg_t = MessageType.UNIT_MOVED;
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
			string er = data_to_str(buf);
			msg = cast(Message)(new ErrorMessage(er));
			msg.Message.msg_t = msg_t;
			break;
		case MessageType.SPAWN_UNIT:
			short x = buf.read!short();
			short y = buf.read!short();
			ulong sid = buf.read!ulong();
			msg = cast(Message)(new SpawnUnitMessage(Point(x, y), sid));
			msg.Message.msg_t = msg_t;
			break;
		case MessageType.LEVEL_DATA:
			import Level;
			Level l = new Level();
			l.map_size = Point(0, 0);
			l.map_size.X = buf.read!short();
			l.map_size.Y = buf.read!short();
			writefln("SIZE %d %d",l.map_size.X, l.map_size.Y);
			l.map.length = l.map_size.X*l.map_size.Y;
			for(int i = 0; i < l.map.length; i++)
			{
				l.map[i].glyph.symbol = buf.read!char();
				l.map[i].glyph.color = buf.read!ushort();
				l.map[i].flags = buf.read!CellFlags();
				l.map[i].movement_cost = buf.read!int();
				l.map[i].baked_light = cast(int)(buf.read!short());
				l.map[i].emit_light = cast(int)(buf.read!short());
				l.map[i].light_level = cast(int)(buf.read!byte());
			}
			int unit_count = buf.read!int();
			for(int i = 0; i < unit_count; i++)
			{
				ulong u_id = buf.read!ulong();
				l.units[u_id] = new Unit();
				l.units[u_id].ID = u_id;
				l.units[u_id].glyph.symbol = buf.read!char();
				l.units[u_id].glyph.color = buf.read!ushort();
				l.units[u_id].position.X = buf.read!short();
				l.units[u_id].position.Y = buf.read!short();
				l.units[u_id].previous_position = l.units[u_id].position;
			}
			l.ambient_light = cast(int)(buf.read!short());
			int light_count = buf.read!int();
			for(int i = 0; i < light_count; i++)
			{
				int l_id = buf.read!int();
				l.lights[l_id] = new Light();
				l.lights[l_id].ID = l_id;
				l.lights[l_id].position.X = buf.read!short();
				l.lights[l_id].position.Y = buf.read!short();
				l.lights[l_id].range = cast(int)(buf.read!ubyte());
				l.lights[l_id].inner_strength = cast(int)(buf.read!short());
				l.lights[l_id].outer_strength = cast(int)(buf.read!short());
				l.lights[l_id].is_on = (buf.read!ubyte() == 1);

			}
			ulong pu_id = buf.read!ulong();
			msg = cast(Message)(new LevelDataMessage(l, pu_id));
			msg.Message.msg_t = msg_t;
			break;
		case MessageType.MOVE_ACTION:
			Direction d = buf.read!Direction();
			msg = cast(Message)(new MoveActionMessage(d));
			msg.Message.msg_t = msg_t;
			break;
		case MessageType.UNIT_MOVED:
			ulong u = buf.read!ulong();
			Point p;
			p.X = buf.read!short();
			p.Y = buf.read!short();
			msg = cast(Message)(new UnitMovedMessage(u, p));
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
		case MessageType.LEVEL_DATA:
			LevelDataMessage msg_ok = cast(LevelDataMessage)msg;
			buf.length = 4+4+(msg_ok).data.map.length*16+4+(msg_ok).data.units.length*15+2+4+(msg_ok).data.lights.length*14+8;

			buf.write!MessageType((msg_ok).msg_t, 0);
			// map size
			buf.write!short((msg_ok).data.map_size.X, 4);
			buf.write!short((msg_ok).data.map_size.Y, 6);
			// map
			int off1 = 8+(msg_ok).data.map.length*16;
			for(int i = 0; i < (msg_ok).data.map.length; i++)
			{
				buf.write!char((msg_ok).data.map[i].glyph.symbol, 8+i*16);
				buf.write!ushort((msg_ok).data.map[i].glyph.color, 8+i*16+1);
				buf.write!CellFlags((msg_ok).data.map[i].flags, 8+i*16+3);
				buf.write!int((msg_ok).data.map[i].movement_cost, 8+i*16+7);
				buf.write!short(cast(short)((msg_ok).data.map[i].baked_light), 8+i*16+11);
				buf.write!short(cast(short)((msg_ok).data.map[i].emit_light), 8+i*16+13);
				buf.write!byte(cast(byte)((msg_ok).data.map[i].light_level), 8+i*16+15);
			}
			// units
			buf.write!int((msg_ok).data.units.length, off1);
			int off2 = 0;
			foreach(u; (msg_ok).data.units.values)
			{
				buf.write!ulong(u.ID, off1+4+off2);
				buf.write!char(u.glyph.symbol, off1+4+off2+8);
				buf.write!ushort(u.glyph.color, off1+4+off2+9);
				buf.write!short(u.position.X, off1+4+off2+11);
				buf.write!short(u.position.Y, off1+4+off2+13);
				off2 += 15;
			}
			// lights
			int off_tmp = off1+4+off2+2;
			buf.write!short(cast(short)((msg_ok).data.ambient_light), off_tmp-2);
			buf.write!int((msg_ok).data.lights.length, off_tmp);
			int off3 = 0;
			foreach(l; (msg_ok).data.lights.values)
			{
				buf.write!int(l.ID, off_tmp+4+off3);
				buf.write!short(l.position.X, off_tmp+4+off3+4);
				buf.write!short(l.position.Y, off_tmp+4+off3+6);
				buf.write!ubyte(cast(ubyte)(l.range), off_tmp+4+off3+8);
				buf.write!short(cast(short)(l.inner_strength), off_tmp+4+off3+9);
				buf.write!short(cast(short)(l.outer_strength), off_tmp+4+off3+11);
				buf.write!ubyte(cast(ubyte)(l.is_on), off_tmp+4+off3+13);
				off3 += 14;
			}
			// player unit id
			buf.write!ulong((msg_ok).player_unitID, off_tmp+4+off3);
			break;
		case MessageType.MOVE_ACTION:
			MoveActionMessage msg_ok = cast(MoveActionMessage)msg;
			buf.length = 8;
			buf.write!MessageType((msg_ok).msg_t, 0);
			buf.write!Direction((msg_ok).dir, 4);
			break;

		case MessageType.UNIT_MOVED:
			UnitMovedMessage msg_ok = cast(UnitMovedMessage)msg;
			buf.length = 16;
			buf.write!MessageType((msg_ok).msg_t, 0);
			buf.write!ulong((msg_ok).u_id, 4);
			buf.write!short((msg_ok).pos.X, 12);
			buf.write!short((msg_ok).pos.Y, 14);
			break;
		default:
			buf.length = 4;
			buf.write!MessageType((msg).msg_t, 0);
			break;
	}
	msg.destroy();
	return buf;
}