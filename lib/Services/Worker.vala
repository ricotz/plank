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
	
	public delegate G TaskFunc<G> () throws Error;
	
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
		
		public void* run ()
		{
			return func ();
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
		
		ThreadPool<Task> pool;
		
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
				error ("Creating ThreadPool failed! (%s)", e.message);
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
			try {
				pool.add (new Task (func, priority));
			} catch (ThreadError e) {
				warning (e.message);
			}
		}
		
		/**
		 * Schedule given function to be run in our ThreadPool
		 * The given priority influences execution-time of the task 
		 * depending on the currently scheduled amount of tasks.
		 *
		 * @param func the function to be executed returning a typed result
		 * @param priority priority of the given function
		 * @return the typed result
		 */
		public async G add_task_with_result<G> (owned TaskFunc<G> func, TaskPriority priority = TaskPriority.DEFAULT) throws Error
		{
			SourceFunc resume = add_task_with_result.callback;
			Error err = null;
			G result = null;
			
			try {
				ThreadFunc tfunc = () => {
					try {
						result = func ();
					} catch (Error e) {
						err = e;
					}
					
					Idle.add ((owned) resume);
					return null;
				};
				pool.add (new Task (tfunc, priority));
			} catch (ThreadError e) {
				warning (e.message);
			}
			
			yield;
			if (err != null)
				throw err;
			
			return result;
		}
	}
}
