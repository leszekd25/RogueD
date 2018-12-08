module utility.ConIO;

import core.stdc.stdio;
extern (C) void _STI_conio(); // initializes DM access ton conin, conout
extern (C) void _STD_conio(); // properly closes handles
extern (C) int kbhit();       // the conio function is in the DMD library
extern (C) int getch();       // as is his friend getch 
extern (C) int isatty(int);

enum WIDTH=100;
enum HEIGHT=33;
enum WH = WIDTH*HEIGHT;

enum FColor : ubyte
{
    black         = 0,
    red           = 1,
    green         = 2,
    blue          = 4,
    yellow        = red | green,
    magenta       = red | blue,
    cyan          = green | blue,
    lightGray     = red | green | blue,
    bright        = 8,
    darkGray      = bright | black,
    brightRed     = bright | red,
    brightGreen   = bright | green,
    brightBlue    = bright | blue,
    brightYellow  = bright | yellow,
    brightMagenta = bright | magenta,
    brightCyan    = bright | cyan,
    white         = bright | lightGray,
}

enum BColor : ubyte
{
    black         = 0,
    red           = 0x10,
    green         = 0x20,
    blue          = 0x40,
    yellow        = red | green,
    magenta       = red | blue,
    cyan          = green | blue,
    lightGray     = red | green | blue,
    bright        = 0x80,
    darkGray      = bright | black,
    brightRed     = bright | red,
    brightGreen   = bright | green,
    brightBlue    = bright | blue,
    brightYellow  = bright | yellow,
    brightMagenta = bright | magenta,
    brightCyan    = bright | cyan,
    white         = bright | lightGray,
}

struct CharInfo
{
	char ascii_char;
	ushort attr;
}

version(Windows)
{
	import core.sys.windows.windows;

	struct Console
	{
	private:
        CONSOLE_SCREEN_BUFFER_INFO sbi;
        HANDLE handle;
		CHAR_INFO[WH] buffer;

        FILE* _fp;

	public:
        @property FILE* fp() { return _fp; }

		static Console* create()
		{
			FILE* fp = stdout;

			DWORD nStdHandle = STD_OUTPUT_HANDLE;

			auto h = GetStdHandle(nStdHandle);

            CONSOLE_SCREEN_BUFFER_INFO sbi;
            if (GetConsoleScreenBufferInfo(h, &sbi) == 0) // get initial state of console
                return null;

			SetConsoleScreenBufferSize(h, COORD(WIDTH, HEIGHT));

            auto c = new Console();
            c._fp = fp;
            c.handle = h;
            c.sbi = sbi;
			c.clear();
            return c;
		}

		void clear()
		{
			for(int i = 0; i < WH; i++)
			{
				buffer[i].Char.AsciiChar = ' ';
				buffer[i].Attributes = 0;
			}

		}

		void put(int x, int y, char c, ushort attr)
		{
			buffer[y*WIDTH+x].Char.AsciiChar = c;
			buffer[y*WIDTH+x].Attributes = attr;
		}

		void put(int x, int y, char[] s, ushort attr)
		{
			assert(y*WIDTH+x+s.length-1 < WH);
			for(int i = 0; i < s.length; i++)
			{
				buffer[y*WIDTH+x+i].Char.AsciiChar = s[i];
				buffer[y*WIDTH+x+i].Attributes = attr;
			}
		}

		void put(int x, int y, CharInfo[] s)
		{
			assert(y*WIDTH+x+s.length-1 < WH);
			for(int i = 0; i < s.length; i++)
			{
				buffer[y*WIDTH+x+i].Char.AsciiChar = s[i].ascii_char;
				buffer[y*WIDTH+x+i].Attributes = s[i].attr;
			}
		}

		void set_color(FColor f, BColor b)
		{
			ushort col = f | b;
            WORD attr = col;
            SetConsoleTextAttribute(handle, attr);
		}

		void refresh_region(short t, short l, short w, short h)
		{
			SMALL_RECT region;
			region.Top = 0;
			region.Left = 0;
			region.Bottom = HEIGHT-1;
			region.Right = WIDTH-1;
			COORD tl;
			tl.X = t;
			tl.Y = l;
			COORD wh;
			wh.X = w;
			wh.Y = h;
			WriteConsoleOutput(handle,
							   buffer.ptr,
							   wh,
							   tl,
							   &region);
		}

		void refresh()
		{
			SMALL_RECT region;
			region.Top = 0;
			region.Left = 0;
			region.Bottom = HEIGHT-1;
			region.Right = WIDTH-1;
			COORD tl;
			tl.X = 0;
			tl.Y = 0;
			COORD wh;
			wh.X = WIDTH;
			wh.Y = HEIGHT;
			CHAR_INFO* pt = buffer.ptr;
			WriteConsoleOutputA(handle,
							   pt,
							   wh,
							   tl,
							   &region);
		}
	}

	
}
else
{
	static assert(0);
}