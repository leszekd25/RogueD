module utility.TemplateReader;

import std.stdio;
import std.file;
import std.string:strip;
import std.array:split;
import std.conv:text;
import std.uni:isWhite;
import std.path : dirName;
import Connections:Queue;


class TemplateReader
{
	string[][int] params;
	File f;
	int max_id = 0;
	this(string filename)
	{
		string path = (thisExePath().dirName())~filename;
		f = File(path, "r");
	}

	~this()
	{
		if(params != null)
			params.destroy();
		if(f.isOpen())
			f.close();
	}

	// reads next entry from file to the queue
	bool ReadNextEntry()
	{
		foreach(l; params.keys)
		{
			params.remove(l);
		}
		string fl;
		bool success = false;
		int cur_command = 0;
		while(!f.eof)
		{
			fl = f.readln().strip();
			if(fl == "")
			{
				if(success)
					break;

				continue;
			}
			if(fl[0] == '#')
				continue;
			success = true;
			// split to array
			string[] pms = fl.split!isWhite;
			/*if((pms[0] in params) !is null)
				params[pms[0]] ~= pms[1 .. $];
			else
				params[pms[0]] = pms[1 .. $];*/
			params[cur_command] = pms;
			cur_command++;
		}
		if(success)
		{
			params[cur_command] = ["id", text(max_id)];
			max_id++;
		}
		return success;
	}

	string[] EntryGetParameter(int param)
	{
		return params[param];
	}

	int EntryGetCommandCount()
	{
		return params.length;
	}
}
