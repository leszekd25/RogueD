module Light;

import utility.Geometry;

class Light
{
	static int max_ID;
	int ID;
	Point position;
	int inner_strength; ///(-100 - 100)
	int outer_strength;
	int range;
	bool is_on = true;

	static this()
	{
		max_ID = 0;
	}

	this()
	{
		
	}

	this(Point p, int r, int i = 100, int o = 0)
	{
		ID = max_ID;
		position = p;
		range = r;
		inner_strength = i;
		outer_strength = o;
		max_ID++;
	}

	int get_strength(int r)
	{
		if(r <= 0)
			return inner_strength;
		if(r > range)
			return 0;
		return inner_strength-(inner_strength-outer_strength)*r;
	}
}