module utility.Geometry;

import utility.IntMath;

struct Point
{
	short X, Y;

	Point opBinary(string op)(Point rhs)
	{
		static if(op == "+") return Point(X+rhs.X, Y+rhs.Y);
		else static if(op == "+") return Point(X+rhs.X, Y+rhs.Y);
	}

	/// Manhattan distance
	short dist(Point p)
	{
		return max(abs(cast(short)(X-p.X)), abs(cast(short)(Y-p.Y)));
	}
}