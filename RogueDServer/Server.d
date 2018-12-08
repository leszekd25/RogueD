module Server;

import std.stdio;
import std.socket;
import Connections;
import Messages;
import Player;
import GameInstance;

struct GClientData
{
	bool alive = false;      //if this is false, the slot can be replaced by new connection
	InternetAddress address;
	Socket client;
	int current_player = -1; //player id currently owned by this client
	Queue!(ubyte[]) send_queue;
	Queue!(Message) recv_queue;
}

class GServer
{
	ulong server_time;
	GClientData[MAX_CONNECTIONS] clients;
	InternetAddress address;
	TcpSocket listener;
	GameInstance game;
	GlobalPlayer[] players; int max_player_id = 0;
	int[string] name_to_player;  //index for searching player ids by name

	this()
	{
		game = new GameInstance();

		address = new InternetAddress(DEFAULT_PORT);
		listener = new TcpSocket();
		assert(listener.isAlive, "Error creating server");
		listener.blocking = false;
		listener.bind(address);
		//listener.setOption(SocketOptionLevel.TCP, SocketOption.SNDBUF, BUFFER_SIZE);
		//listener.setOption(SocketOptionLevel.TCP, SocketOption.RCVBUF, BUFFER_SIZE);
		listener.listen(10);
		writefln("Created server");

		game = new GameInstance();
		game.base_level.Test();
	}

	// Player manipulation goes here--------------------------------------------------------------

	void CreatePlayer(string n, string p)
	{
		players ~= new GlobalPlayer();
		players[max_player_id].name = n;
		players[max_player_id].password = p;
		players[max_player_id].ID = max_player_id;
		name_to_player[n] = max_player_id;
		max_player_id++;
		writefln("Created player ID %d", max_player_id-1);
	}

	void DeletePlayer(int p_id)
	{
		GlobalPlayer p = players[p_id];
		assert(!p.deleted, "Error deleting player: Player already deleted!");
		assert(!(p.isPlaying), "Error deleting player: Player in game!");
		players[p_id].deleted = true;
		name_to_player.remove(players[p_id].name);
	}

	void PlayerJoinGame(int p_id)
	{
		GlobalPlayer p = players[p_id];
		assert(!p.deleted, "Error joining game: Player deleted!");
		assert(!p.isPlaying, "Error joining game: Player already in game!");

		p.isPlaying = true;
		game.AddPlayerToGame(p);
	}

	void PlayerLeaveGame(int p_id)
	{
		GlobalPlayer p = players[p_id];
		assert(!p.deleted, "Error leaving game: Player deleted!");
		assert(p.isPlaying, "Error leaving game: Player not in game!");

		game.RemovePlayerFromGame(p_id);
		p.isPlaying = false;
	}

	//--------------------------------------------------------------------------------------------

	int FindEmptyClientSlot()
	{
		for(int i = 0; i < MAX_CONNECTIONS; i++)
			if(!clients[i].alive)
				return i;
		return -1;
	}

	void DropConnection(int c_id)
	{
		Message msg = new Message(MessageType.DISCONNECT);
		clients[c_id].send_queue.push(MessageToBuffer(msg));
		clients[c_id].alive = false;
	}

	void SendClientMessage(Message msg, int c_id)
	{
		clients[c_id].send_queue.push(MessageToBuffer(msg));
	}

	void HandleNetworking()
	{
		// 1. listen for new connections
		while(true)
		{
			Socket cl_socket = null;

			try
				cl_socket = listener.accept();
			catch(SocketAcceptException)
			{
				break;
			}

			if(!cl_socket.isAlive)// "Error creating a connection");
				break;

			int next_empty = FindEmptyClientSlot();
			if(next_empty == -1)
			{
				writefln("Rejected connection: Client slots all taken!");
			}
			else
			{
				clients[next_empty].client = cl_socket;
				clients[next_empty].alive = true;
				clients[next_empty].send_queue = new Queue!(ubyte[])();
				clients[next_empty].recv_queue = new Queue!(Message)();

				writefln("Accepted and created a connection, client ID %d", next_empty);
			}
		}
		// 2. data manip
		for(int i = 0; i < MAX_CONNECTIONS; i++)
		{
			if(clients[i].alive == false)
				break;
			// receive loop
			while(true)
			{
				int[1] header;  //buf length
				int recv_data = clients[i].client.receive(header[]);
				if(recv_data == Socket.ERROR)
				{
					//do some timing and disconnect if too long wait
					break;
				}
				if(recv_data == 0)
				{
					//disconnect this socket
					clients[i].client.close();
					clients[i].alive = false;
					writefln("Closed connection to client id %d", i);
					break;
				}

				ubyte[] buffer = new ubyte[header[0]];
				int data_length = clients[i].client.receive(buffer[]);
				assert(header[0] == data_length);

				Message msg = BufferToMessage(buffer);
				//writefln("RECV %d", data_length);
				bool msg_pushed = false;
				//writefln("RECEIVED DATA FROM C_ID %u %u", i, (msg).msg_t);
				//process data
				switch((msg).msg_t)
				{
					case MessageType.EXIT:
						DropConnection(i);
						writeln("CLIENT C_ID %d EXIT REQUEST", i);
						PlayerLeaveGame(clients[i].current_player);
						break;
					case MessageType.REGISTER:
						LogInMessage msg_ok = cast(LogInMessage)msg;
						int* p_id = ((msg_ok).name in name_to_player);
						if(p_id is null)
						{
							CreatePlayer((msg_ok).name, (msg_ok).password);
							SendClientMessage(new Message(MessageType.REGISTER_OK), i);
						}
						else
						{
							SendClientMessage(new Message(MessageType.REGISTER_FAILED), i);
						}
						break;
					case MessageType.LOG_IN:
						if(clients[i].current_player != -1)
						{
							SendClientMessage(new Message(MessageType.LOG_IN_FAILED), i);
							break;
						}
						LogInMessage msg_ok = cast(LogInMessage)msg;
						int* p_id = ((msg_ok).name in name_to_player);
						if(p_id !is null)
						{
							if(players[*p_id].password == (msg_ok).password)
							{
								clients[i].current_player = *p_id;
								PlayerJoinGame(*p_id);
								SendClientMessage(new Message(MessageType.LOG_IN_OK), i);
								break;
							}
						}
						SendClientMessage(new Message(MessageType.LOG_IN_FAILED), i);
						break;
					case MessageType.LOG_OUT:
						clients[i].current_player = -1;
						SendClientMessage(new Message(MessageType.LOG_OUT_OK), i);
						break;

					case MessageType.READY_TO_LOAD_LEVEL:
						//determine which level to load (for now, only base level (-1))
						LevelDataMessage msg_ok = new LevelDataMessage(game.base_level);
						msg_ok.Message.msg_t = MessageType.LEVEL_DATA;
						SendClientMessage(cast(Message)msg_ok, i);
						break;

					default:
						clients[i].recv_queue.push(msg);
						msg_pushed = true;
						break;
				}
				if(!msg_pushed)
					msg.destroy();
			}
			// game step
			// send loop
			while(true)
			{
				if(clients[i].send_queue.empty())
					break;

				ubyte[] msg = clients[i].send_queue.pop();
				int[1] snd_lgt = [msg.length];

				int send_data = clients[i].client.send(snd_lgt);
				if(send_data == Socket.ERROR)
				{
					break;
				}

				int snd_sent = clients[i].client.send(msg);

				//writefln("SEND %d %d", msg.length, snd_sent);
				assert(snd_sent == msg.length);

			}
		}
		// 3. game forward
		//also remove messages from here
	}
}