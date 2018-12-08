module RogueDServer;

import core.thread;
import core.time;
import std.stdio;
import Messages;
import Server;

int main()
{
    writeln("Hello D World!\n");

	GServer s = new GServer();
	while(true)
	{
		s.HandleNetworkingState();
		s.HandleNetworkingInput();
		s.game.ProcessInput();
		s.game.ProcessStep();
		s.HandleNetworkingOutput();
		Thread.sleep( dur!("msecs")( 33 ) );
		//writeln("Step of 1 sec");
	}

    return 0;
}
