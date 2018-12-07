module Connections;

import std.container.dlist;

enum CONNECT_STATE  {DISCONNECTING, DISCONNECTED, CONNECTING, CONNECTED}

enum DEFAULT_PORT = 8081;
enum MAX_CONNECTIONS = 2;
enum BUFFER_SIZE = 65536;

enum TRY_CONNECT_TIMEOUT = 15; //seconds
enum CONNECTION_LOST_TIMEOUT = 10; //seconds

class Queue(T)
{
	DList!T list;

	this()
	{
		list = DList!T();
	}

	void push(T elem)
	{
		list.insertFront(elem);
	}

	T pop()
	{
		T elem = list.back;
		list.removeBack();
		return elem;
	}

	T next()
	{
		return list.back;
	}

	bool empty()
	{
		return(list.empty);
	}
}