/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace Supplement {
	
public class Argument : GLib.Object {
	
	List<string> args;
	
	public Argument (string line) {
		args = new List<string> ();
		set_argument (line);
	}
	
	public Argument.command_line (string[] arg) {	
		args = new List<string> ();

		foreach (string a in arg) {
			args.append (a);
		}
	}
	
	/** returns 0 if valid or index the bad parameter. */ 
	public int validate () {
		string prev = "";
		int i = 0;
		foreach (string a in args) {
			
			// program name
			if (i == 0) {
				prev = a;
				i++;
				continue;
			}
			
			// file name
			if (i == 1 && !a.has_prefix ("-")) {
				prev = a;
				i++;
				continue;
			}

			// a single character, like -t
			if (!a.has_prefix ("--") && a.has_prefix ("-")) {
				a = expand_param (a);
			}
			
			// valid parameter
			if (a == "--exit" || a == "--slow" || a == "--help" || a == "--test" || a == "--fatal-warning" || a == "--show-coordinates") {
				prev = a;
				i++;
				continue;
			} else if (a.has_prefix ("--")) {
				return i;
			}
			
			// not argument to parameter
			if (!(prev == "--test")) {
				return i;
			}
			
			prev = a;
			i++;
		}
		
		return 0;
	}
	
	/** Return the font file parameter. */
	public string get_file () {
		string f = "";
		
		if (args.length () >= 2) {
			f = args.nth (1).data;
		}

		if (f.has_prefix ("-")) {
			return "";
		}
		
		return f;
	}
	
	public void print_all () {
		print (@"$(args.length ()) arguments:\n");
		
		foreach (string p in args) {
			print (@"$p\n");
		}
	}
	
	public bool has_argument (string param) {
		return (get_argument (param) != null);
	}
	
	/** Get commandline argument. */
	public string? get_argument (string param) {
		int i = 0;
		string? n;
		string p;

		if (param.substring (0, 1) != "-") {
			warning (@"parameters must begin with \"-\" got $param");
			return null;
		}

		foreach (string s in args) {

			// this is content not a parameter 
			if (s.substring (0, 1) != "-") continue;

			// we might need to expand -t to test fo instance
			if (s.substring (0, 2) != "--") {
				p = expand_param (s);
			} else {				
				p = s;
			}
			
			if (param == p) {
				if (i + 2 >= args.length ()) {
					return "";
				}
				
				n = args.nth (i + 2).data;
				if (n == null) {
					return "";
				}
				
				if (args.nth (i + 2).data.substring (0, 1) == "-") {
					return "";
				}
				
				return args.nth (i + 2).data;
			}
			
			i++;
		}
		
		return null;
	}

	private void print_padded (string cmd, string desc) {
		int l = 25 - cmd.char_count ();

		stdout.printf (cmd);
		
		for (int i = 0; i < l; i++) {
				stdout.printf (" ");
		}
		
		stdout.printf (desc);
		stdout.printf ("\n");
	}

	/** Return full command line parameter for the abbrevation.
	 * -t becomes --test.
	 */
	private string expand_param (string? param) {
		if (param == null) return "";
		var p = (!) param;
		
		if (p.length == 0) return "";
		if (p.get_char (0) != '-') return "";
		if (p.char_count () != 2) return "";
		
		switch (p.get_char (1)) {
			case 'c':
				return "--show-coordinates";
			case 'e': 
				return "--exit";
			case 'f': 
				return "--fatal-warning";
			case 'h': 
				return "--help";
			case 's': 
				return "--slow";
			case 't': 
				return "--test";
		}
		
		return "";
	}

	private void set_argument (string arg) {
		int i = 0;
		int a;
		string n;
		
		if (arg.char_count () <= 1) {
			return;
		}
		
		do {
			a = arg.index_of (" ", i + 1);
			n = arg.substring (i, a - i);
			
			if (n.index_of ("\"") == 0) {
				a = arg.index_of ("\"", i + 1);
				n = arg.substring (i, a - i + 1);
			}
					
			args.append (n);
			
			i += n.char_count () + 1;
		} while (i < arg.char_count ());
	}

	public void print_help () 
		requires (args.length () > 0)
	{
		stdout.printf (_("Usage") + ": ");
		stdout.printf (args.nth (0).data);
		stdout.printf (" [FILE] [OPTION ...]\n");

		print_padded ("-c, --show-coordinates", _("show coordinate in glyph view"));
		print_padded ("-e, --exit", _("exit if a testcase failes"));
		print_padded ("-f, --fatal-warning", _("treat warnings as fatal"));
		print_padded ("-h, --help", _("show this message"));
		print_padded ("-s, --slow", _("sleep between each command in test suite"));
		print_padded ("-t, --test [TEST]", _("run test case"));
		
		stdout.printf ("\n");
	}

}
	
}
