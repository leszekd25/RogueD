module TemplateDatabase;

import utility.TemplateReader;
import std.conv:parse;

interface DataTemplate
{
	void ReadTemplate(TemplateReader tr);
}

template TemplateDatabase(T: DataTemplate)
{
	class TemplateDatabase
	{
		T[] data;
		int[string] name_to_index;

		this(string filename)
		{
			T[string] tmp_data;

			// 1. read templates to temporary assoc array
			TemplateReader tr = new TemplateReader(filename);
			while(tr.ReadNextEntry())
			{
				T tmp = new T();
				tmp.ReadTemplate(tr);
				tmp_data[tr.EntryGetParameter("name")[0]] = tmp;
				name_to_index[tr.EntryGetParameter("name")[0]] = parse!int(tr.EntryGetParameter("id")[0]);
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