module utility.IntMath;

// pending optimization...

short sgn(short x) pure nothrow
{
	return (x>0?1:(x==0?0:-1));
}

short abs(short x) pure nothrow
{
	return cast(short)(x>0?x:-x);
}

short max(short x, short y) pure nothrow
{
	return (x>y?x:y);
}

short min(short x, short y) pure nothrow
{
	return (x<y?x:y);
}