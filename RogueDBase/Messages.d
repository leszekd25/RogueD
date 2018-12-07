module Messages;

import std.bitmanip;
import std.stdio;

enum MessageType {DISCONNECT}

struct Message  // base type message
{
	MessageType msg_t;
}

Message BufferToMessage(ubyte[] buf)
{
	//writeln(buf.length);
	Message msg;
	MessageType msg_t = buf.read!MessageType();
	switch(msg_t)
	{
		case MessageType.DISCONNECT:
			msg = Message(msg_t);
			break;
		default:
			break;
	}
	return msg;
}

ubyte[] MessageToBuffer(ref Message msg)
{
	ubyte[] buf;
	switch(msg.msg_t)
	{
		case MessageType.DISCONNECT:
			buf.length = 4;
			buf.write!MessageType(msg.msg_t, 0);
			break;
		default:
			break;
	}
	return buf;
}