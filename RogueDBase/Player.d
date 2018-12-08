module Player;

import utility.Geometry;
import Entity;

/// this is for database
class GlobalPlayer
{
	bool deleted = false;
	int ID;
	int clientID = -1;     // required for communication between server and game
	string name;
	string password;
	bool isPlaying = false;
	// level persistence data
	int levelID = -1;     //-1 = base level
	Point lastPosition = Point(-1, -1);
}



enum ActionType {ACTION_MOVE, ACTION_ATTACK, ACTION_CAST}

abstract class PlayerAction
{
	ActionType act_t;

	this()
	{

	}
}

class PlayerActionMove: PlayerAction
{
	Direction dir;

	this(Direction d)
	{
		act_t = ActionType.ACTION_MOVE;
		dir = d;
	}
}

// this is for gaming
class Player
{
	int ID;    // same as global player
	ulong unitID = -1;

	PlayerAction action = null;
	int bonus_action_counter = 0;     //if a unit didn't move in the first action window, it will be still able to consume that action
	bool action_charging = false; //as long as the bonus counter is charging

	void SetAction(PlayerAction a)
	{
		if(action !is null)
			action.destroy();
		action = a;
	}
}