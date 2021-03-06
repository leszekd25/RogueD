module Client;

import std.stdio;
import std.socket;
import Connections;
import Messages;
import core.time;
import utility.ConIO: FColor, BColor;
import GameLog;
import ClientGameInstance;
import std.format: format;

interface INetClient
{
	CONNECT_STATE Connect();
	CONNECT_STATE Disconnect();
	void SendMessage(Message msg);
	void ReceiveMessage(Message msg);
	void HandleNetworkingState();
	void HandleNetworkingInput();
	void HandleNetworkingOutput();
	void Ping();
}

class TCPGClient: INetClient
{
	InternetAddress address;
	TcpSocket server;
	CONNECT_STATE connect_mode;
	bool connected =  false;
	bool is_receiving_length = true;
	int length_header;
	Queue!(ubyte[]) send_queue;
	Queue!(Message) recv_queue;
	ClientGameInstance game = null;
	MonoTime ping_timer;
	ulong client_time = 0;
	Duration ping;
	string name, password;
	bool logged_in = false;

	this()
	{
		address = new InternetAddress("127.0.0.1", DEFAULT_PORT);
		send_queue = new Queue!(ubyte[])();
		recv_queue = new Queue!(Message)();
		connect_mode = CONNECT_STATE.DISCONNECTED;
		name = "Bartosz";
		password = "hunter2";
	}

	void SendMessage(Message msg)
	{
		ubyte[] buf = MessageToBuffer(msg);
		send_queue.push(buf);
	}

	void ReceiveMessage(Message msg)
	{
		msg = BufferToMessage(send_queue.pop());
	}

	CONNECT_STATE Connect()
	{
		if(connect_mode != CONNECT_STATE.DISCONNECTED)
			return connect_mode;

		server = new TcpSocket();
		server.blocking = false;

		server.connect(address);

		connect_mode = CONNECT_STATE.CONNECTING;
		ping_timer = MonoTime();
		Log.Write("CONNECTING...");
		return connect_mode;
	}

	CONNECT_STATE Disconnect()
	{		
		if((connect_mode != CONNECT_STATE.CONNECTED)&&(connect_mode != CONNECT_STATE.DISCONNECTING))
			return connect_mode;

		connect_mode = CONNECT_STATE.DISCONNECTING;
		return connect_mode;
	}

	void TryLogin()
	{
		assert(!logged_in);
		assert(connected);
		LogInMessage msg = new LogInMessage(name,password);
		SendMessage(msg);
	}

	void TryRegister()
	{
		assert(!logged_in);
		assert(connected);
		LogInMessage msg = new LogInMessage(name,password);
		msg.msg_t = MessageType.REGISTER;
		SendMessage(msg);
	}

	void LogOut()
	{
		assert(logged_in);
		assert(connected);
		Message msg = new Message(MessageType.LOG_OUT);
		SendMessage(msg);
	}

	void HandleNetworkingState()
	{
		switch(connect_mode)
		{
			case CONNECT_STATE.DISCONNECTED:
				break;
			case CONNECT_STATE.CONNECTING:
				if(server.isAlive)
				{
					connect_mode = CONNECT_STATE.CONNECTED;
					connected = true;
					Log.Write("Connected", FColor.brightGreen, LogMessageType.CLIENT);
					break;
				}
				Duration d = (MonoTime()-ping_timer);
				if(d > TRY_CONNECT_TIMEOUT.seconds)
					Disconnect();
				break;
			case CONNECT_STATE.DISCONNECTING:
				server.close();
				connect_mode = CONNECT_STATE.DISCONNECTED;
				connected = false;
				Log.Write("Disconnected", FColor.brightYellow, LogMessageType.CLIENT);
				break;
			default:
				break;
		}
	}


	void HandleNetworkingInput()
	{
		switch(connect_mode)
		{
			case CONNECT_STATE.CONNECTED:
				//receive loop
				while(true)
				{
					if(is_receiving_length)
					{
						int[1] lgt_h;
						int recv_data = server.receive(lgt_h[]);
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
						length_header = lgt_h[0];
						is_receiving_length = false;
						continue;
					}
					else
					{
						ubyte[] buffer = new ubyte[length_header];
						int data_length = server.receive(buffer[]);
						if(data_length == Socket.ERROR)
						{
							//do some timing and disconnect if too long wait
							break;
						}
						if(length_header != data_length)
							Log.Write(format!"RECV %d %d"(length_header, data_length));
						assert(length_header == data_length);
						is_receiving_length = true;
						//process data
						Message msg = BufferToMessage(buffer);
						MessageType msg_t = msg.msg_t;
						bool msg_pushed = false;

						switch(msg_t)
						{
							case MessageType.REGISTER_OK:
								Log.Write("Register successful", FColor.brightGreen, LogMessageType.SERVER);
								break;
							case MessageType.REGISTER_FAILED:
								Log.Write("Register failed!", FColor.brightYellow, LogMessageType.SERVER);
								break;
							case MessageType.LOG_IN_OK:
								Log.Write("Login successful", FColor.brightGreen, LogMessageType.SERVER);
								SendMessage(new Message(MessageType.READY_TO_LOAD_LEVEL));
								logged_in = true;
								break;
							case MessageType.LOG_IN_FAILED:
								Log.Write("Login failed!", FColor.brightYellow, LogMessageType.SERVER);
								break;						
							case MessageType.LOG_OUT_OK:
								Log.Write("Logout successful", FColor.brightGreen, LogMessageType.SERVER);
								logged_in = false;
								break;
							case MessageType.LOG_OUT_FAILED:
								Log.Write("Logout failed!", FColor.brightYellow, LogMessageType.SERVER);
								break;
							case MessageType.DISCONNECT:
								Disconnect();
								break;
							case MessageType.PING:
								ping = MonoTime()-ping_timer;
								break;
							default:
								recv_queue.push(msg);
								msg_pushed = true;
								break;
						}
						if(!msg_pushed)
							msg.destroy();
					}
				}
				//send queue to game
				game.messages_in = recv_queue;
				break;
			default:
				break;
		}
	}

	void HandleNetworkingOutput()
	{
		switch(connect_mode)
		{
			case CONNECT_STATE.CONNECTED:
				//receive queue from game
				while(!(game.messages_out.empty))
				{
					Message msg = game.messages_out.pop();
					send_queue.push(MessageToBuffer(msg));
				}
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
					//Log.Write(format!"SEND %d %d"(snd_sent, msg.length));
					assert(snd_sent == msg.length);
				}
				break;
			default:
				break;
		}
	}

	void Ping()
	{
		assert(connected);
		Message msg = new Message(MessageType.PING);
		SendMessage(msg);
		ping_timer = MonoTime();
	}
}