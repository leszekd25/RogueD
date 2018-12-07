module Client;

import std.stdio;
import std.socket;
import Connections;
import Messages;

interface INetClient
{
	CONNECT_STATE Connect();
	CONNECT_STATE Disconnect();
	void SendMessage(ref Message msg);
	void ReceiveMessage(ref Message msg);
	void HandleNetworking();
}

class TCPGClient: INetClient
{
	InternetAddress address;
	TcpSocket server;
	CONNECT_STATE connect_mode;
	Queue!(ubyte[]) send_queue;
	Queue!(Message) recv_queue;

	this()
	{
		address = new InternetAddress("127.0.0.1", DEFAULT_PORT);
		send_queue = new Queue!(ubyte[])();
		recv_queue = new Queue!(Message)();
		connect_mode = CONNECT_STATE.DISCONNECTED;
	}

	CONNECT_STATE Connect()
	{
		if(connect_mode != CONNECT_STATE.DISCONNECTED)
			return connect_mode;

		server = new TcpSocket();
		server.blocking = false;
		//server.set_option(SocketOptionLevel.TCP, SocketOption.SNDBUF, BUFFER_SIZE);
		//server.set_option(SocketOptionLevel.TCP, SocketOption.RCVBUF, BUFFER_SIZE);

		connect_mode = CONNECT_STATE.CONNECTING;
		writeln("CONNECTING");
		return connect_mode;
	}

	CONNECT_STATE Disconnect()
	{		
		if(connect_mode != CONNECT_STATE.CONNECTED)
			return connect_mode;

		connect_mode = CONNECT_STATE.DISCONNECTING;
		return connect_mode;
	}

	void SendMessage(ref Message msg)
	{
		ubyte[] buf = MessageToBuffer(msg);
		send_queue.push(buf);
	}

	void ReceiveMessage(ref Message msg)
	{
		msg = BufferToMessage(send_queue.pop());
	}

	void HandleNetworking()
	{
		switch(connect_mode)
		{
			case CONNECT_STATE.DISCONNECTED:
				break;
			case CONNECT_STATE.CONNECTING:
				server.connect(address);

				connect_mode = CONNECT_STATE.CONNECTED;
				writeln("CONNECTED");
				break;
			case CONNECT_STATE.CONNECTED:
				//receive loop
				while(true)
				{
					int[1] next_length;
					int recv_data = server.receive(next_length[]);
					if(recv_data == Socket.ERROR)
					{
						//do some timing and disconnect if too long wait

						break;
					}
					if(recv_data == 0)
					{
						connect_mode = CONNECT_STATE.DISCONNECTING;
						break;
					}

					ubyte[] buffer = new ubyte[next_length[0]];
					int data_length = server.receive(buffer[]);
					assert(recv_data == data_length);
					//process data
					Message msg = BufferToMessage(buffer);
					recv_queue.push(msg);

					if(msg.msg_t == MessageType.DISCONNECT)
					{
						Disconnect();
					}
				}
				//send queue to game

				//receive queue from game
				//send loop
				while(true)
				{
					if(send_queue.empty())
						break;

					ubyte[] msg = send_queue.pop();
					int[1] snd_lgt = [msg.length];
					
					int send_data = server.send(snd_lgt);
					if(send_data == Socket.ERROR)
					{
						break;
					}
					
					int snd_sent = server.send(msg);
					assert(snd_sent == msg.length);

				}
				break;
			case CONNECT_STATE.DISCONNECTING:
				server.close();
				connect_mode = CONNECT_STATE.DISCONNECTED;
				writeln("DISCONNECTED");
				break;
			default:
				assert(0);
		}
	}
}