module ClientGameInstance;

import Cell;
import Entity;
import Messages;
import ClientGameView:ClientGameView;
import Connections: Queue;
import utility.ConIO;
import utility.Geometry;

enum PROCESS_RESULT {OK, CONNECT, DISCONNECT, EXIT}
/*
ok:  nothing new
connect: connect to server
disconnect: drop connection
exit: exit program
*/

class ClientGameInstance
{
	Cell[] map;
	Point size;
	Unit[ulong] units;
	Queue!(Message) messages_out = new Queue!(Message)();
	Queue!(Message) messages_in = new Queue!(Message)();

	this(short w, short h)
	{
		size = Point(w, h);
		map = new Cell[h*w];
	}

	~this()
	{
		map.destroy();
	}

	int point_to_map(Point coord)
	{
		return coord.Y*size.X+coord.X;
	}

	ref Cell get_cell(Point p)
	{
		return map[point_to_map(p)];
	}

	PROCESS_RESULT ProcessMessages()
	{
		PROCESS_RESULT result;
		if(kbhit() > 0)
		{
			char c = cast(char)getch();
			switch(c)
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
		return result;
	}
}