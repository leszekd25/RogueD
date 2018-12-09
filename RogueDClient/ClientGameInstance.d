module ClientGameInstance;

import Cell;
import Level;
import Entity;
import Messages;
import GameLog;
import Connections: Queue;
import ClientGameView:ClientGameView;
import utility.ConIO;
import utility.Geometry;
import std.format:format;

enum PROCESS_RESULT {OK, CONNECT, DISCONNECT, EXIT}
/*
ok:  nothing new
connect: connect to server
disconnect: drop connection
exit: exit program
*/

const Direction[char] move_keys;

static this()
{
	move_keys = 
	[
		77: Direction.E,
		81: Direction.SE,
		80: Direction.S,
		79: Direction.SW,
		75: Direction.W,
		71: Direction.NW,
		72: Direction.N,
		73: Direction.NE
	];
}

class ClientGameInstance
{
	Level level = null;
	ulong player_unitID = -1;
	ulong client_step = 0;
	Queue!(Message) messages_out = new Queue!(Message)();
	Queue!(Message) messages_in = new Queue!(Message)();

	PROCESS_RESULT ProcessMessages()
	{
		while(!(messages_in.empty))
		{
			Message msg = messages_in.pop();
			MessageType msg_t = msg.msg_t;

			switch(msg_t)
			{
				case MessageType.LEVEL_DATA:
					LevelDataMessage msg_ok = cast(LevelDataMessage)msg;
					if(level !is null)
						level.destroy();
					level = msg_ok.data;
					ClientGameView.level = level;
					ClientGameView.SetEntityFollow(cast(Entity)(level.units[msg_ok.player_unitID]));
					ClientGameView.RequestMapRedraw();
					player_unitID = msg_ok.player_unitID;
					break;
				case MessageType.UNIT_MOVED:
					UnitMovedMessage msg_ok = cast(UnitMovedMessage)msg;
					level.units[msg_ok.u_id].previous_position = level.units[msg_ok.u_id].position;
					level.units[msg_ok.u_id].position = msg_ok.pos;
					ClientGameView.EntityRedraw(cast(Entity)(level.units[msg_ok.u_id]));
					break;
				default:
					break;
			}
		}

		PROCESS_RESULT result;
		char[2] keycode;
		int keys_pressed = 0;
		for(int i = 0; i < 2; i++)
		{
			if(kbhit() <= 0)
				break;
			keycode[i] = cast(char)getch();
			keys_pressed = i+1;
		}
		assert(keys_pressed != 1);
		if(keys_pressed == 0)
			return PROCESS_RESULT.OK;
		
		if(keycode[0]!=0)
		{
			//Log.Write(format!"char1 id %d"(cast(int)(keycode[0])));
			switch(keycode[0])
			{
				case 'x':
					// register
					LogInMessage msg = new LogInMessage("bartosz", "hunter2");
					msg.Message.msg_t = MessageType.REGISTER;
					messages_out.push(cast(Message)msg);
					break;
				case 'l':
					// log in
					LogInMessage msg = new LogInMessage("bartosz", "hunter2");
					messages_out.push(cast(Message)msg);
					break;
				case 'o':
					// log out
					Message msg = new Message(MessageType.LOG_OUT);
					messages_out.push(msg);
					break;
				case 'p':
					// connect
					result = PROCESS_RESULT.CONNECT;
					break;
				case ';':
					// disconnect
					result = PROCESS_RESULT.DISCONNECT;
					break;
				default:
					break;
			}
		}
		else 
		{
			//Log.Write(format!"char2 id %d"(cast(int)(keycode[1])));
			switch(keycode[1])
			{
				case 71:
				case 72:
				case 73:
				case 75:
				case 77:
				case 79:
				case 80:
				case 81:
					MoveActionMessage msg = new MoveActionMessage(move_keys[keycode[1]]);
					messages_out.push(cast(Message)msg);
					break;
				default:
					break;
			}
		}
		client_step++;
		/*if(client_step%30 == 0)
		{
			if(level !is null)
			{
				foreach(u; level.units.values)
				{
					Log.Write(format!"UNIT %d, POS (%d, %d)"(u.ID, u.position.X, u.position.Y));
				}
			}
		}*/
		return result;
	}
}