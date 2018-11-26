docklet_applications_sources = [
	'ApplicationsDockItem.vala',
	'ApplicationsDocklet.vala',
]

docklet_applications = shared_module(
	'docklet-applications',
	docklet_applications_sources,
	dependencies: [plank_dep, plank_base_dep, gnomemenu_dep],
	install: true,
	install_dir: docklets_dir,
)
