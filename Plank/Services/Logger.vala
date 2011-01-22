//  
//  Copyright (C) 2011 Robert Dyer
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 

namespace Plank.Services
{
	public enum LogLevel
	{
		DEBUG,
		INFO,
		NOTIFY,
		WARN,
		ERROR,
		FATAL,
	}
	
	enum ConsoleColor
	{
		BLACK,
		RED,
		GREEN,
		YELLOW,
		BLUE,
		MAGENTA,
		CYAN,
		WHITE,
	}
	
	public class Logger : GLib.Object
	{
		class LogMessage : GLib.Object
		{
			public LogLevel Level { get; private set; }
			public string Message { get; private set; }
			
			public LogMessage (LogLevel level, string message)
			{
				Level = level;
				Message = message;
			}
		}
		
		public static LogLevel DisplayLevel { get; set; default = LogLevel.WARN; }
		
		public static string AppName { get; set; }
		
		static Object queue_lock = null;
		
		static List<LogMessage> log_queue;
		static bool is_writing;
		
		static string[] domains = {
			"Gtk",
			"Gdk",
			"GLib",
			"GLib-GObject",
			"Pango",
			"GdkPixbuf",
			"GLib-GIO"
		};
		
		public static void initialize (string app_name)
		{
			AppName = app_name;
			is_writing = false;
			log_queue = new List<LogMessage> ();
			
			LogLevelFlags flags = LogLevelFlags.LEVEL_MASK | LogLevelFlags.FLAG_FATAL | LogLevelFlags.FLAG_RECURSION;
			
			Log.set_handler (null, flags, glib_log_func);
			foreach (string domain in domains)
				Log.set_handler (domain, flags, glib_log_func);
		}
		
		static string format_message<T> (string msg)
		{
			return "[%s] %s".printf (typeof (T).name (), msg);
		}
		
		public static void debug<T> (string msg)
		{
			write (LogLevel.DEBUG, format_message<T> (msg));
		}
		
		public static void info<T> (string msg)
		{
			write (LogLevel.INFO, format_message<T> (msg));
		}
		
		public static void notification<T> (string msg)
		{
			write (LogLevel.NOTIFY, format_message<T> (msg));
		}
		
		public static void warn<T> (string msg)
		{
			write (LogLevel.WARN, format_message<T> (msg));
		}
		
		public static void error<T> (string msg)
		{
			write (LogLevel.ERROR, format_message<T> (msg));
		}
		
		public static void fatal<T> (string msg)
		{
			write (LogLevel.FATAL, format_message<T> (msg));
			write (LogLevel.FATAL, format_message<T> (AppName + " will not function properly."));
		}
		
		static string get_time ()
		{
			var now = new DateTime.now_local ();
			return "%.2d:%.2d:%.2d.%.3d".printf (now.get_hour (), now.get_minute (), now.get_second (), now.get_microsecond ());
		}
		
		static void write (LogLevel level, string msg)
		{
			if (level < DisplayLevel)
				return;
			
			if (is_writing) {
				lock (queue_lock)
					log_queue.append (new LogMessage (level, msg));
			} else {
				is_writing = true;
				
				if (log_queue.length () > 0) {
					unowned List<LogMessage> logs = log_queue;
					lock (queue_lock)
						log_queue = new List<LogMessage> ();
					
					stdout.printf("hi!\n");
					stdout.printf("hi!\n");
					stdout.printf("hi!\n");
					foreach (LogMessage log in logs)
						print_log (log);
				}
				
				print_log (new LogMessage (level, msg));
				
				is_writing = false;
			}
		}
		
		static async void print_log (LogMessage log)
		{
			set_color_for_level (log.Level);
			stdout.printf ("[%s %s] ", log.Level.to_string ().substring (25), get_time ());
			
			reset_color ();
			stdout.printf (log.Message + "\n");
		}
		
		static void set_color_for_level (LogLevel level)
		{
			switch (level) {
			case LogLevel.DEBUG:
				set_foreground (ConsoleColor.GREEN);
				break;
			case LogLevel.INFO:
				set_foreground (ConsoleColor.BLUE);
				break;
			case LogLevel.NOTIFY:
				set_foreground (ConsoleColor.MAGENTA);
				break;
			case LogLevel.WARN:
				set_foreground (ConsoleColor.YELLOW);
				break;
			case LogLevel.ERROR:
				set_foreground (ConsoleColor.RED);
				break;
			case LogLevel.FATAL:
				set_background (ConsoleColor.RED);
				set_foreground (ConsoleColor.WHITE);
				break;
			}
		}
		
		static void reset_color ()
		{
			stdout.printf ("\x001b[0m");
		}
		
		static void set_foreground (ConsoleColor color)
		{
			set_color (color, true);
		}
		
		static void set_background (ConsoleColor color)
		{
			set_color (color, false);
		}
		
		static void set_color (ConsoleColor color, bool isForeground)
		{
			var color_code = color + 30 + 60;
			if (!isForeground)
				color_code += 10;
			stdout.printf ("\x001b[%dm", color_code);
		}
		
		static void glib_log_func (string? d, LogLevelFlags flags, string msg)
		{
			string domain;
			if (d == null)
				domain = "";
			else
				domain = "[%s] ".printf (d);
			
			string message = msg.replace ("\n", "").replace ("\r", "");
			
			string format = "%s%s";
			
			switch (flags) {
			case LogLevelFlags.LEVEL_CRITICAL:
				fatal<Logger> (format.printf (domain, message));
				break;
			
			case LogLevelFlags.LEVEL_ERROR:
				error<Logger> (format.printf (domain, message));
				break;
			
			case LogLevelFlags.LEVEL_WARNING:
				warn<Logger> (format.printf (domain, message));
				break;
			
			case LogLevelFlags.LEVEL_INFO:
			case LogLevelFlags.LEVEL_MESSAGE:
				info<Logger> (format.printf (domain, message));
				break;
			
			case LogLevelFlags.LEVEL_DEBUG:
				debug<Logger> (format.printf (domain, message));
				break;
			
			default:
				warn<Logger> (format.printf (domain, message));
				break;
			}
		}
	}
}
