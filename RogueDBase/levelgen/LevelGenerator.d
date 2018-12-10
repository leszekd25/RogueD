module levelgen.LevelGenerator;

import Cell;
import Level;
import TemplateDatabase:TemplateDatabase,DataTemplate;
import utility.TemplateReader;
import utility.Geometry;

enum LevelGenBaseMode {NONE = -1, VALUE_NOISE = 0, DRUNKARD_WALK = 1, BSP = 2, MAZE = 3, CELLULAR_AUTOMATA = 4}

class LevelGenTemplate: DataTemplate
{
	LevelGenBaseMode base_mode;
	double[string] params;
	string ctf_name;
	string ctw_name;

	override void ReadTemplate(TemplateReader tr)
	{
		import std.conv:parse;

		base_mode = parse!LevelGenBaseMode(tr.EntryGetParameter("base_mode")[0]);
		ctf_name = tr.EntryGetParameter("floor_cell")[0];
		ctw_name = tr.EntryGetParameter("wall_cell")[0];
		if(tr.EntryHasParameter("param"))
		{
			string[] tmp_params = tr.EntryGetParameter("param");
			for(int i = 0; i < tmp_params.length; i+=2)
				params[tmp_params[i]] = parse!double(tmp_params[i+1]);
		}
	}
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

// highest abstraction level map generator
static Level LevelFromTemplate(LevelGenTemplate tmpl, TemplateDatabase!CellTemplate cell_db, int width, int height)
{
	Level l;
	switch(tmpl.base_mode)
	{
		case LevelGenBaseMode.NONE:
			LevelGenNone lg = new LevelGenNone();
			lg.GetCellTemplates(tmpl, cell_db);
			lg.GetGeneratorParameters(tmpl);
			l = lg.Generate(width, height);
			lg.destroy();
			break;
		default:
			assert(0);
	}
	return l;
}