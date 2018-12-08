module utility.Geometry;

import utility.IntMath;

enum Direction {E = 0, NE, N, NW, W, SW, S, SE}

struct Point
{
	short X, Y;

	Point opBinary(string op)(Point rhs)
	{
		static if(op == "+") return Point(cast(short)(X+rhs.X), cast(short)(Y+rhs.Y));
		else static if(op == "-") return Point(cast(short)(X-rhs.X), cast(short)(Y-rhs.Y));
	}

	/// Manhattan distance
	short dist(Point p)
	{
		return max(abs(cast(short)(X-p.X)), abs(cast(short)(Y-p.Y)));
	}
}

static Point[] Neighbor = [Point(1, 0), Point(1, -1), Point(0, -1), Point(-1, -1),
						   Point(-1, 0), Point(-1, 1), Point(0, 1), Point(1, 1)];