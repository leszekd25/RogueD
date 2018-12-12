module TemplateDatabase;

import utility.TemplateReader;
import Connections:Queue;
import std.conv:parse;

interface DataTemplate
{
	void ParseCommands(ref string[][int] commands);
}

template TemplateDatabase(T: DataTemplate)
{
	class TemplateDatabase
	{
		T[] data;
		int[string] name_to_index;

		this(string filename)
		{
			void SplitIntoCommands(TemplateReader tr, ref string[][int] commands)
			{
				for(int i = 1; i < tr.EntryGetCommandCount()-1; i++)
					commands[i-1] = tr.EntryGetParameter(i);
			}

			T[string] tmp_data;

			// 1. read templates to temporary assoc array
			TemplateReader tr = new TemplateReader(filename);
			while(tr.ReadNextEntry())
			{
				// read template, then name and id
				// first command is always name, last command is always id
				T tmp = new T();
				string[][int] com;
				SplitIntoCommands(tr, com);
				tmp.ParseCommands(com);
				tmp_data[tr.EntryGetParameter(0)[1]] = tmp;
				name_to_index[tr.EntryGetParameter(0)[1]] = parse!int(tr.EntryGetParameter(tr.EntryGetCommandCount()-1)[1]);
			}
			// 2. move all data to real array
			data.length = tmp_data.length;
			foreach(name; tmp_data.keys)
				data[name_to_index[name]] = tmp_data[name];

			tr.destroy();
		}

		T Get(int i)
		{
			return data[i];
		}

		T Get(string n)
		{
			return data[name_to_index[n]];
		}
	}
}