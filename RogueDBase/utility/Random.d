module utility.Random;

import std.datetime.systime;

/// http://www.pcg-random.org/
static class PCG
{
	static ulong state;
	static const ulong inc;

	static this()
	{
		state = cast(ulong)(Clock.currTime().toUnixTime!long());
		inc = 0x7B414F;   // ensures inc is odd
	}
	
	static uint next()
	{
		ulong oldstate = state;
		state = oldstate * 6364136223846793005UL + inc;   // assumed inc is odd!

		uint xorshifted = cast(uint)(((oldstate >> 18u) ^ oldstate) >> 27u);
		uint rot = oldstate >> 59u;
		return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
	}
}

int randrange(int xinc, int yinc)
{
	return xinc+(PCG.next() % (yinc-xinc));
}

int randrangei(int xinc, int yinc)
{
	return xinc+(PCG.next() % (1+yinc-xinc));
}

uint dice(uint n, uint x)
{
	if(n==1)
		return n;
	uint sum = 0;
	for(int i = 0; i < n; i++)
		sum += randrange(1, x+1);
	return sum;
}

template TChoice(T)
{
	T choose(T[] from)
	{
		return from[PCG.next()%from.length];
	}

	void shuffle(T[] src)
	{
		T sub;
		for(int i = 0; i < src.length; i++)
			if(PCG.next()%2)
			{
				sub = src[i];
				src[i] = src[0];
				src[0] = sub;
			}
	}
}

// dont really use this... i suspect this to be slow
template TChoice(T: T[U], U)
{
	U choosekey(T[U] from)
	{
		return (from.keys)[PCG.next()%from.length];
	}

	T chooseval(T[U] from)
	{
		return (from.values)[PCG.next()%from.length];
	}
}