module Player;

import utility.Geometry;
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
	int levelID = -1;     //-1 = base level
	Point lastPosition = Point(-1, -1);
}

// this is for gaming
class Player
{
	int ID;    // same as global player
	ulong unitID = -1;
}
