module GameInstance;

import Level;
import Player;
import Messages;
import Entity;
import Connections:Queue;
import utility.ConIO;
import std.stdio;

import utility.Geometry;

import TemplateDatabase:TemplateDatabase;
import Cell;
import levelgen.LevelGenerator;

class PlayerMsgWrapper
{
	int playerID;
	Message msg;

	this(int i, Message m)
	{
		playerID = i;
		msg = m;
	}

	~this()
	{
		msg.destroy();
	}
}

class GameInstance
{
	bool deleted = false;
	ulong global_step = 0;
	Level base_level;   //base level which every player starts from
	Player[int] players_in_game;
	ulong max_unit_id = 0;

	Queue!(PlayerMsgWrapper) messages_out = new Queue!(PlayerMsgWrapper)();
	Queue!(PlayerMsgWrapper) messages_in = new Queue!(PlayerMsgWrapper)();

	TemplateDatabase!CellTemplate cell_database = null;
	TemplateDatabase!LevelGenTemplate levelgen_database = null;

	//
	this()
	{
		cell_database = new TemplateDatabase!CellTemplate("\\gamedata\\templates_cell.txt");
		levelgen_database = new TemplateDatabase!LevelGenTemplate("\\gamedata\\templates_levelgen.txt");
		foreach(s; cell_database.name_to_index.keys)
			writeln("Registered cell template "~s);
		foreach(s; levelgen_database.name_to_index.keys)
			writeln("Registered level generator template "~s);
		base_level = new Level();
	}

	void SendMessage(int p_id, Message msg)
	{
		messages_out.push(new PlayerMsgWrapper(p_id, msg));
	}

	void AddPlayerToGame(GlobalPlayer p)
	{
		//add player to game
		Player pl = new Player();
		pl.ID = p.ID;
		pl.unitID = max_unit_id;
		players_in_game[pl.ID] = pl;

		//create unit for player
		//remporary: only base level supported
		Point st_pos = p.lastPosition;
		if(st_pos.X == -1)
			st_pos = base_level.starting_point;
		base_level.AddUnitToLevel(st_pos, max_unit_id);
		base_level.units[max_unit_id-1].glyph.symbol = '@';
		base_level.units[max_unit_id-1].glyph.set_color(FColor.white);
	}

	/// remove player from this instance
	void RemovePlayerFromGame(int p_id)
	{
		Player* p = (p_id in players_in_game);
		assert(p !is null, "Error: Can't remove player from the game: No player found!");

		//remove character from the map
		// temporary: only base_level supported
		base_level.RemoveUnitFromLevel((*p).unitID);

		players_in_game[p_id].destroy();
		players_in_game.remove(p_id);
	}

	void ProcessInput()
	{
		while(!messages_in.empty())
		{
			PlayerMsgWrapper msg_in = messages_in.pop();
			MessageType msg_t = msg_in.msg.msg_t;
			int p_id = msg_in.playerID;

			Player* p = (p_id in players_in_game);
			assert(p !is null, "Error: Can't get player input: No player found!");

			switch(msg_t)
			{
				case MessageType.MOVE_ACTION:
					MoveActionMessage msg = cast(MoveActionMessage)(msg_in.msg);
					(*p).SetAction(new PlayerActionMove(msg.dir));
					break;
				default:
					break;
			}

			msg_in.destroy();
		}
	}
	void ProcessStep()
	{
		// foreach level... only base level for now
		// 1. player actions first!
		foreach(p; players_in_game)
		{
			Level l = base_level;  //temp, only base level supported
			Unit u = l.units[p.unitID];
			// 1a. if player is still cooling down from the last action, continue
			if(!l.UnitCanDoAction(p.unitID))
				continue;


			// 1b. if player can do action and is not charging and charge counter is 0, start charging
			if((!p.action_charging)&&(p.bonus_action_counter == 0))
				p.action_charging = true;
			// 1c. if player is charging, add charges to counter, if counter exceeds a value, stop charging
			if(p.action_charging)
			{
				p.bonus_action_counter+= l.step_multiplier;
				if(p.bonus_action_counter >= u.base_action_time)
					p.action_charging = false;
			}

			// 1d. process actions
			if(p.action is null)
				continue;
			//writeln("ACTION PROCESSING P_ID %d", p.ID);
			PlayerAction a = p.action;
			bool action_done = false;
			switch(a.act_t)  // action type
			{
				case ActionType.ACTION_MOVE:
					PlayerActionMove am = cast(PlayerActionMove)a;
					Point pos = l.units[p.unitID].position + Neighbor[cast(int)(am.dir)];
					if(!l.CanMoveToCell(pos))
					{
						// todo: send message that move failed
						break;
					}
					l.UnitMoveTo(p.unitID, pos);
					action_done = true;
					//writeln("ACTION DONE P_ID %d", p.ID);
					// todo: send to ALL players
					SendMessage(p.ID, new UnitMovedMessage(p.unitID, pos));
					break;
				default:
					break;
			}
			p.action.destroy();
			p.action = null;

			if(!action_done)
				continue;

			// if action is charging, set unit counter to player counter and stop charging;
			if(p.action_charging)
			{
				u.next_action_time = l.step+(u.base_action_time-p.bonus_action_counter);
				p.action_charging = false;
			}
			else // otherwise set unit counter normally
			{
				u.next_action_time = l.step+u.base_action_time;
			}
			// remember to reset charge counter after an action
			p.bonus_action_counter = 0;

		}
		

		// 2. queued enemy actions

		base_level.step += base_level.step_multiplier;
		global_step++;
	}
}