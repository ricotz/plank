//
//  Copyright (C) 2015 Rico Tzschichholz
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

namespace Plank.Services
{
	const int MAX_THREAD_COUNT = 3;
	
	public enum TaskPriority {
		LOW,
		DEFAULT,
		HIGH,
	}
	
	[Compact]
	class Task
	{
		public ThreadFunc<void*> func;
		public TaskPriority priority;
		
		public Task (owned ThreadFunc<void*> _func, TaskPriority _priority)
		{
			func = _func;
			priority = _priority;
		}
		
		public void run ()
		{
			func ();
		}
	}
	
	public class Worker : Object
	{
		static Worker? worker = null;
		
		public static unowned Worker get_default ()
		{
			if (worker == null)
				worker = new Worker ();
			return worker;
		}
		
		ThreadPool<Task>? pool;
		
		private Worker ()
		{
		}
		
		construct
		{
			try {
				pool = new ThreadPool<Task>.with_owned_data ((task) => {
					task.run ();
				}, MAX_THREAD_COUNT, true);
				
				pool.set_sort_function ((CompareDataFunc) compare_task_priority);
			} catch (ThreadError e) {
				critical ("Creating ThreadPool failed! (%s)", e.message);
				pool = null;
			}
		}
		
		static int compare_task_priority (Task t1, Task t2)
		{
			int p1 = t1.priority, p2 = t2.priority;
			return (p1 < p2 ? -1 : (int) (p1 > p2));
		}
		
		/**
		 * Schedule given function to be run in our ThreadPool
		 * The given priority influences execution-time of the task 
		 * depending on the currently scheduled amount of tasks.
		 *
		 * @param func function to be executed
		 * @param priority priority of the given function
		 */
		public void add_task (owned ThreadFunc<void*> func, TaskPriority priority = TaskPriority.DEFAULT)
		{
			if (pool == null) {
				critical ("ThreadPool not available!");
				func ();
				return;
			}
			
			try {
				pool.add (new Task (func, priority));
			} catch (ThreadError e) {
				warning (e.message);
			}
		}
	}
}
