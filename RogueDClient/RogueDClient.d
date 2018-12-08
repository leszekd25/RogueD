module RogueDClient;

import core.thread;
import core.time;
import std.stdio;
import Messages;
import Client;
import ClientGameInstance;
import ClientGameView:ClientGameView;

int main()
{
    writeln("Hello D World!\n");

	TCPGClient c = new TCPGClient();
	ClientGameInstance g = new ClientGameInstance();
	ClientGameView.game = &g;
	c.game = &g;

	ClientGameView.gameLog.Write("start!");
	int i = 0;
	while(true)
	{
		c.HandleNetworkingState();
		c.HandleNetworkingInput();
		PROCESS_RESULT pr = g.ProcessMessages();
		if(pr == PROCESS_RESULT.CONNECT)
		{
			c.Connect();
		}
		else if(pr == PROCESS_RESULT.DISCONNECT)
		{
			c.Disconnect();
		}
		else if(pr == PROCESS_RESULT.EXIT)
		{
			break;
		}
		ClientGameView.DrawFrame();
		c.HandleNetworkingOutput();
		Thread.sleep( dur!("msecs")( 33 ) );
		//writeln("Step of 1 sec");
		i+=1;
	}

    return 0;
}
