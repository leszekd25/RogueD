module levelgen.LevelGenerator;

import Cell;
import Level;
import TemplateDatabase:TemplateDatabase,DataTemplate;
import utility.TemplateReader;
import utility.Geometry;
import Connections:Queue;

enum LevelGenBaseMode {NONE = -1, NOISE = 0, DRUNKARD = 1, BSP = 2, MAZE = 3, CELLULAR = 4}

class LevelGenTemplate: DataTemplate
{
	LevelGenBaseMode base_mode;
	string[][int] gen_params;
	string ctf_name;
	string ctw_name;

	void ParseCommands(ref string[][int] commands)
	{
		import std.conv:to;

		int gp_count = 0;
		for(int i =  0; i < commands.length; i++)
		{
			string[] command = commands[i];
			switch(command[0])
			{
				case "base_mode":
					base_mode = to!LevelGenBaseMode(command[1]);
					break;
				case "floor_cell":
					ctf_name = command[1];
					break;
				case "wall_cell":
					ctw_name = command[1];
					break;
				default:
					gen_params[gp_count] = command;
					gp_count++;
					break;
			}
		}
	}

	int GenGetCommandCount()
	{
		return gen_params.length;
	}

	string[] GenGetCommand(int i)
	{
		return gen_params[i];
	}
}
struct CellTopologyInfo
{
	Point position;
	int wall_distance;
	int number_of_neighbors;
	int group_id;
	int home_step_distance;
	int home_weighted_distance;
	int movement_cost;
	Point came_from;
}

abstract class LevelGenerator
{
	CellTemplate floor_cell;
	CellTemplate wall_cell;

	void GetGeneratorParameters(LevelGenTemplate tmpl);
	void GetCellTemplates(LevelGenTemplate tmpl, TemplateDatabase!CellTemplate cell_db)
	{
		floor_cell = cell_db.Get(tmpl.ctf_name);
		wall_cell = cell_db.Get(tmpl.ctw_name);
	}
	Level Generate(int width, int height);
	void PasteCell(Level l, int off, CellTemplate tmpl)
	{
		l.map[off].glyph = tmpl.glyph;
		l.map[off].flags = tmpl.flags;
		l.map[off].movement_cost = tmpl.movement_cost;
		l.map[off].emit_light = tmpl.emit_light;
	}
}

class LevelGenNone: LevelGenerator
{
	override void GetGeneratorParameters(LevelGenTemplate tmpl) {return;}
	override Level Generate(int width, int height)
	{
		int wh = width*height;
		Level l = new Level();
		l.map_size = Point(cast(short)width, cast(short)height);
		l.starting_point = Point(cast(short)(width/2), cast(short)(height/2));
		l.map.length = width*height;
		for(int i = 0; i < wh; i++)
			PasteCell(l, i, floor_cell);
		int offset = l.toOffset(Point(3, 3));
		PasteCell(l, offset, wall_cell);
		PasteCell(l, offset+1, wall_cell);
		PasteCell(l, offset+2, wall_cell);
		for(int i = 0; i < wh; i++)
			l.ComputeLightPowerAtCell(l.toPoint(i));
		return l;
	}
}