docklet_desktop_sources = [
	'DesktopDockItem.vala',
	'DesktopDocklet.vala',
]

docklet_desktop_resources = gnome.compile_resources(
	'docky-desktop-resources',
	'desktop.gresource.xml',
	c_name: 'docky_desktop',
)

docklet_desktop = shared_module(
	'docklet-desktop',
	docklet_desktop_sources,
	docklet_desktop_resources,
	dependencies: [plank_dep, plank_base_dep, wnck_x11_dep],
	install: true,
	install_dir: docklets_dir,
)
