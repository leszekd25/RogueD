module RogueDClient;

import core.thread;
import core.time;
import std.stdio;
import Messages;
import Client;

int main()
{
    writeln("Hello D World!\n");

	TCPGClient c = new TCPGClient();
	c.Connect();
	int i = 0;
	while(true)
	{
		c.HandleNetworking();
		Thread.sleep( dur!("msecs")( 1000 ) );
		//writeln("Step of 1 sec");
		i+=1;
	}

    return 0;
}
