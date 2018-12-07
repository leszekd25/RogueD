module Player;

import Entity;

/// this is for database
class GlobalPlayer
{
	bool deleted = false;
	int ID;
	string name;
	string password;
	bool isPlaying = false;
	// level persistence data
	int gameID = -1;
}

// this is for gaming
class Player
{
	int ID;
	int gameID = -1;
	ulong unitID = -1;
}
