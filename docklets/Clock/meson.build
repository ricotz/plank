docklet_clock_sources = [
	'ClockDockItem.vala',
	'ClockDocklet.vala',
	'ClockPreferences.vala',
]

docklet_clock_resources = gnome.compile_resources(
	'docky-clock-resources',
	'clock.gresource.xml',
	c_name: 'docky_clock',
)

docklet_clock = shared_module(
	'docklet-clock',
	docklet_clock_sources,
	docklet_clock_resources,
	dependencies: [plank_dep, plank_base_dep],
	install: true,
	install_dir: docklets_dir,
)
