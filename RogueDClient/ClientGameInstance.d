module ClientGameInstance;

import Cell;
import Level;
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
	Level level = null;
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
					level = msg_ok.data;
					break;
				default:
					break;
			}
		}

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