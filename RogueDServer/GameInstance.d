module GameInstance;

import Level;
import Player;
import utility.ConIO;

import utility.Geometry;

class GameInstance
{
	bool deleted = false;
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
}