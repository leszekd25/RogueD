module utility.ConIO;

import core.stdc.stdio;
extern (C) int isatty(int);

enum WIDTH=100;
enum HEIGHT=32;
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
        CONSOLE_SCREEN_BUFFER_INFO[2] sbi;
        HANDLE[2] handle;
		CHAR_INFO[WH] buffer;

		int active_buffer;
        FILE* _fp;

	public:
        @property FILE* fp() { return _fp; }

		static Console* create()
		{
			FILE* fp = stdout;

			DWORD nStdHandle = STD_OUTPUT_HANDLE;

			HWND conw = GetConsoleWindow();

			auto h = GetStdHandle(nStdHandle);

			CONSOLE_FONT_INFO font_info;
			GetCurrentConsoleFont(h, false, &font_info);
			SetWindowPos(conw, HWND_TOP, 0, 0, font_info.dwFontSize.X*WIDTH, font_info.dwFontSize.Y*HEIGHT, 0);
			SetConsoleScreenBufferSize(h, COORD(WIDTH, HEIGHT));


            CONSOLE_SCREEN_BUFFER_INFO sbi;
            if (GetConsoleScreenBufferInfo(h, &sbi) == 0) // get initial state of console
                return null;

			auto h2 = CreateConsoleScreenBuffer(GENERIC_READ |           // read/write access 
												GENERIC_WRITE, 
												FILE_SHARE_READ | 
												FILE_SHARE_WRITE,        // shared 
												NULL,                    // default security attributes 
												CONSOLE_TEXTMODE_BUFFER, // must be TEXTMODE 
												NULL);                   // reserved; must be NULL )
			CONSOLE_SCREEN_BUFFER_INFO sbi2;
            if (GetConsoleScreenBufferInfo(h2, &sbi2) == 0) // get initial state of console
                return null;

            auto c = new Console();
            c._fp = fp;
            c.handle[0] = h;
            c.sbi[0] = sbi;
			c.handle[1] = h2;
            c.sbi[1] = sbi2;
			c.active_buffer = 0;
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
            SetConsoleTextAttribute(handle[active_buffer], attr);
		}

		void swap()
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
			WriteConsoleOutput(handle[active_buffer],
							   buffer.ptr,
							   tl,
							   wh,
							   &region);
			SetConsoleActiveScreenBuffer(handle[active_buffer]);
			active_buffer ^= 1;
		}
	}

	
}
else
{
	static assert(0);
}