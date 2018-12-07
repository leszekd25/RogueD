module GameInstance;

import Level;
import Player;

class GameInstance
{
	bool deleted = false;
	int ID;
	ulong global_step = 0;
	Level base_level;   //base level which every player starts from
	Player[int] players_in_game;
	ulong max_unit_id = 0;

	//
	this()
	{
		base_level = new Level();
	}

	void AddPlayerToGame(GlobalPlayer p)
	{
		Player pl = new Player();
		pl.ID = p.ID;
		pl.gameID = ID;
		pl.unitID = max_unit_id;

		base_level.AddUnitToLevel(base_level.starting_point, max_unit_id);

		players_in_game[pl.ID] = pl;

		p.gameID = ID;
	}

	/// remove player from this instance
	void RemovePlayerFromGame(int p_id)
	{
		Player* p = (p_id in players_in_game);
		assert(p !is null, "Error: Can't remove player from the game: No player found!");
		assert((*p).gameID == ID, "Error: Can't remove player from the game: ID mismatch!!");

		//remove character from the map
		// temporary: only base_level supported
		base_level.RemoveUnitFromLevel((*p).unitID);

		players_in_game.remove(p_id);

		(*p).gameID = -1;
	}
}