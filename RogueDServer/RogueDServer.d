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
	int i = 0;
	while(true)
	{
		s.HandleNetworking();
		Thread.sleep( dur!("msecs")( 33 ) );
		//writeln("Step of 1 sec");
		i+=1;
	}

    return 0;
}
