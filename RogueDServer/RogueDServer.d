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
		MonoTime m1 = MonoTime();
		s.HandleNetworkingState();
		s.HandleNetworkingInput();
		s.game.ProcessInput();
		s.game.ProcessStep();
		s.HandleNetworkingOutput();
		MonoTime m2 = MonoTime();
		Duration durr = m2-m1;
		if(durr < dur!("msecs")( 33 ))
			Thread.sleep( dur!("msecs")( 33 ) - durr );
		//writeln("Step of 1 sec");
	}

    return 0;
}
