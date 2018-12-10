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
	bool opEquals(const Point rhs) 
	{
		return(X==rhs.X)&&(Y==rhs.Y);
	}


	/// Manhattan distance
	short dist(Point p)
	{
		return max(abs(cast(short)(X-p.X)), abs(cast(short)(Y-p.Y)));
	}
}

static Point[] Neighbor = [Point(1, 0), Point(1, -1), Point(0, -1), Point(-1, -1),
						   Point(-1, 0), Point(-1, 1), Point(0, 1), Point(1, 1)];

Point[] GenerateRing(Point p, int r)
{
	Point[] res;
	res.length = 8*r;
	for(int i = 0; i <= 2*r; i++)
		res[i] = p+Point(cast(short)(r-i),cast(short)(-r));
	for(int i = 0; i <= 2*r; i++)
		res[i+2*r+1] = p+Point(cast(short)(r-i), cast(short)(r));
	for(int i = 1; i <= 2*r-1; i++)
		res[i+4*r+1] = p+Point(cast(short)(r), cast(short)(r-i));
	for(int i = 1; i <= 2*r-1; i++)
		res[i+6*r] = p+Point(cast(short)(-r), cast(short)(r-i));
	return res;
}

struct Ray
{
	Point e;   // end point
	Point c;   // current point
	Point d;   // delta
	Point i;   // iteration sign
	int error;
	Point delegate() Next;   // for speed up

	this(Point st, Point en)
	{
		import std.math:abs;
		short sign(short s) { return cast(short)((s>0)-(s<0));}

		e = en;
		c = st;
		d = e-st;
		i = Point(sign(d.X), sign(d.Y));
		d = Point(cast(short)(abs(d.X)<<1), cast(short)(abs(d.Y)<<1));

		if(d.X >= d.Y)
		{
			Next = &step_dX;
			error = d.Y - (d.X >> 1);
		}
		else
		{
			Next = &step_dY;
			error = d.X - (d.Y >> 1);
		}
	}

	bool isDone()
	{
		return c==e;
	}

	Point step_dY()
	{
		// reduce error, while taking into account the corner case of error == 0
        if ((error > 0) || ((error == 0) && (i.Y > 0)))
        {
            error -= d.Y;
            c.X += i.X;
        }
        // else do nothing

        error += d.X;
        c.Y += i.Y;

        return c;
	}

	Point step_dX()
	{
        // reduce error, while taking into account the corner case of error == 0
        if ((error > 0) || ((error == 0) && (i.X > 0)))
        {
            error -= d.X;
            c.Y += i.Y;
        }
        // else do nothing

        error += d.Y;
        c.X += i.X;

        return c;
	}
}

unittest
{
	Point start = Point(0, 0);
	Point end = Point(3, 3);

	Ray ray = Ray(start, end);
	assert(!ray.isDone());
	Point p = ray.Next();
	assert(p == Point(1, 1));
	p = ray.Next();
	assert(p == Point(2, 2));
    p = ray.Next();
	assert(p == Point(3, 3));
	assert(ray.isDone());
}