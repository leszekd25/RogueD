module levelgen.CellularGenerator;

import Level;
import levelgen.LevelGenerator;
import std.container.dlist;
import utility.Random;
import Cell;
import std.stdio;
import utility.Geometry;

struct Rule
{
	bool to_wall;
	int w_num;
	int n_reg;
	char op;
	bool nb_only;
}

class Ruleset
{
	DList!Rule rules = DList!Rule();

	~this()
	{
		foreach(r; rules)
			r.destroy();
		rules.destroy();
	}
}

class LevelGenCellular: LevelGenerator
{
	int initial_percentage;
	Ruleset[string] rulesets;
	DList!Ruleset iterations = DList!Ruleset();

	~this()
	{
		foreach(rs; rulesets.values)
			rs.destroy();
		iterations.destroy();
	}

	override void GetGeneratorParameters(LevelGenTemplate tmpl)
	{
		import std.conv:to;
		for(int i =  0; i < tmpl.gen_params.length; i++)
		{
			string[] command = tmpl.gen_params[i];
			switch(command[0])
			{
				case "init":
					initial_percentage = to!int(command[1]);
					break;
				case "floor":
				case "wall":
					bool to_wall = (command[0]=="wall");
					if((command[1] in rulesets) is null)
						rulesets[command[1]] = new Ruleset();
					int w = to!int(command[2]);
					int n = to!int(command[3]);
					char c = command[4][0];
					bool o = false;
					if(command.length > 5)
						o = true;
					rulesets[command[1]].rules.insertBack(Rule(to_wall, w, n, c, o));
					break;
				case "iter":
					int n = to!int(command[2]);
					for(int v = 0; v < n; v++)
						iterations.insertBack(rulesets[command[1]]);
					break;
				default:
					break;
			}
		}
	}

	override Level Generate(int width, int height)
	{
		int wh = width*height;
		Level l = new Level();
		l.map_size = Point(cast(short)width, cast(short)height);
		//l.starting_point = Point(cast(short)(width/2), cast(short)(height/2));
		l.map.length = width*height;
		
		// generate map
		byte[] walls;
		byte[] new_walls;
		walls.length = wh;
		new_walls.length = wh;
		for(int i = 0; i < wh; i++)
		{
			int rn = randrange(0, 100);
			if(rn < initial_percentage)
			{
				walls[i] = 1;
				new_walls[i] = 1;
			}
		}

		auto itr = iterations[];     // slices are a mess
		foreach(rs; itr)
		{
			for(int i = 0; i < wh; i++)
			{
				if(new_walls[i]&2)
					continue;
				foreach(r; rs.rules[])
				{
					if((walls[i])&&(r.to_wall))
						continue;
					if((!(walls[i]))&&(!(r.to_wall)))
						continue;
					int sum = 0;
					for(int y = -(r.n_reg); y <= r.n_reg; y++)
						for(int x = -(r.n_reg); x <= r.n_reg; x++)
						{
							int off = (i+(y*width+x));
							if(!(l.IsValidCell(off)))
								sum += 1;
							else
								sum += walls[off];
						}
					if(r.nb_only)
						sum -= walls[i];
					int success = false;
					switch(r.op)
					{
						case '>':
							if(sum > r.w_num)
								success = true;
							break;

						case '=':
							if(sum == r.w_num)
								success = true;
							break;

						case '<':
							if(sum < r.w_num)
								success = true;
							break;
						default:
							break;
					}
					if(success)
						new_walls[i] = cast(byte)(cast(int)(r.to_wall) | 2);
				}
			}
			for(int i = 0; i < wh; i++)
			{
				walls[i] = new_walls[i]&1;
				new_walls[i] = walls[i];
			}
		}


		for(int i = 0; i < wh; i++)
		{
			PasteCell(l, i, (walls[i])?wall_cell:floor_cell);
			l.ComputeLightPowerAtCell(l.toPoint(i));
		}

		while(true)
		{
			l.starting_point = Point(cast(short)randrange(0, width), cast(short)randrange(0, height));
			if(l.map[l.toOffset(l.starting_point)].flags & CellFlags.blocksMovement)
				continue;
			break;
		}
		

		return l;
	}
}