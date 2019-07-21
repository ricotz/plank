docklet_calendar_sources = [
	'CalendarDockItem.vala',
	'CalendarDocklet.vala',
	'CalendarPreferences.vala',
]

docklet_calendar_resources = gnome.compile_resources(
	'docky-calendar-resources',
	'calendar.gresource.xml',
	c_name: 'docky_calendar',
)

docklet_calendar = shared_module(
	'docklet-calendar',
	docklet_calendar_sources,
	docklet_calendar_resources,
	dependencies: [plank_dep, plank_base_dep],
	install: true,
	install_dir: docklets_dir,
)
