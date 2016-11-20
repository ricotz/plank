//
//  Copyright (C) 2011 Robert Dyer
//                2015 Rico Tzschichholz
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Plank
{
	const string[] LOG_LEVEL_TO_STRING = {
		"VERBOSE",
		"DEBUG",
		"INFO",
		"NOTIFY",
		"WARN",
		"CRITICAL",
		"ERROR",
	};
	
	/**
	 * Controls what messages show in the console log.
	 */
	public enum LogLevel
	{
		/**
		 * Extra debugging info. A *LOT* of messages.
		 */
		VERBOSE,
		/**
		 * Debugging messages that help track what the application is doing.
		 */
		DEBUG,
		/**
		 * General information messages. Similar to debug but perhaps useful to non-debug users.
		 */
		INFO,
		/**
		 * Messages that also show a libnotify message.
		 */
		NOTIFY,
		/**
		 * Any messsage that is a warning.
		 */
		WARN,
		/**
		 * Any message considered critical. These can be recovered from but might make the application function abnormally.
		 */
		CRITICAL,
		/**
		 * Any message considered an error. These generally break the application.
		 */
		ERROR,
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
	
	/**
	 * A logging class to display all console messages in a nice colored format.
	 */
	public class Logger : GLib.Object
	{
		/**
		 * The current log level.  Controls what log messages actually appear on the console.
		 */
		public static LogLevel DisplayLevel { get; set; default = LogLevel.WARN; }
		
		static string app_domain;
		static Mutex write_mutex;
		static Regex message_regex;
		
		Logger ()
		{
		}
		
		/**
		 * Initializes the logger for the application.
		 *
		 * @param app_name the name of the application
		 */
		public static void initialize (string app_name)
		{
			app_domain = app_name;
			
			message_regex = /[(]?.*?([^\/]*?)(\.2)?\.vala(:\d+)[)]?:\s*(.*)/;
			
			Log.set_default_handler ((GLib.LogFunc) glib_log_func);
		}
		
		static string format_message (string msg)
		{
			if (message_regex != null && message_regex.match (msg)) {
				var parts = message_regex.split (msg);
				return "[%s%s] %s".printf (parts[1], parts[3], parts[4]);
			}
			return msg;
		}
		
		/**
		 * Displays a log message using libnotify.  Also displays on the console.
		 *
		 * @param msg the log message to display
		 * @param icon the icon to display in the notification
		 */
		public static void notification (string msg, string icon = "")
		{
			// TODO display the message using libnotify
			write (LogLevel.NOTIFY, format_message (msg));
		}
		
		/**
		 * Displays a verbose log message to the console.
		 *
		 * @param msg the log message to display
		 */
		public static void verbose (string msg, ...)
		{
			write (LogLevel.VERBOSE, format_message (msg.vprintf (va_list ())));
		}
		
		static string get_time ()
		{
			var now = new DateTime.now_local ();
			return "%.2d:%.2d:%.2d.%.6d".printf (now.get_hour (), now.get_minute (), now.get_second (), now.get_microsecond ());
		}
		
		static void write (LogLevel level, owned string msg)
		{
			if (level < DisplayLevel)
				return;

			write_mutex.lock ();
			
			set_color_for_level (level);
			stdout.printf ("[%s %s]", LOG_LEVEL_TO_STRING[level], get_time ());
			
			reset_color ();
			stdout.printf (" %s\n", msg);
			
			write_mutex.unlock ();
		}
		
		static void set_color_for_level (LogLevel level)
		{
			switch (level) {
			case LogLevel.VERBOSE:
				set_foreground (ConsoleColor.CYAN);
				break;
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
			default:
				set_foreground (ConsoleColor.YELLOW);
				break;
			case LogLevel.CRITICAL:
				set_foreground (ConsoleColor.RED);
				break;
			case LogLevel.ERROR:
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
			if (d != null)
				domain = "[%s] ".printf (d);
			else
				domain = "";
			
			string message;
			if (msg.contains ("\n") || msg.contains ("\r"))
				message = "%s%s".printf (domain, msg.replace ("\n", "").replace ("\r", ""));
			else
				message = "%s%s".printf (domain, msg);
			
			LogLevel level;
			
			// Strip internal flags to make it possible to use a switch-statement
			flags = (flags & LogLevelFlags.LEVEL_MASK);
			
			switch (flags) {
			case LogLevelFlags.LEVEL_ERROR:
				level = LogLevel.ERROR;
				break;
			case LogLevelFlags.LEVEL_CRITICAL:
				level = LogLevel.CRITICAL;
				break;
			case LogLevelFlags.LEVEL_INFO:
			case LogLevelFlags.LEVEL_MESSAGE:
				level = LogLevel.INFO;
				break;
			case LogLevelFlags.LEVEL_DEBUG:
				level = LogLevel.DEBUG;
				break;
			case LogLevelFlags.LEVEL_WARNING:
			default:
				level = LogLevel.WARN;
				break;
			}
			
			write (level, format_message (message));
		}
	}
}
