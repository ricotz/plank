plank_lib_sources = [
	'DBusManager.vala',
	'DockController.vala',
	'DockPreferences.vala',
	'DockRenderer.vala',
	'DragManager.vala',
	'HideManager.vala',
	'PositionManager.vala',
	'DBus/Client.vala',
	'DBus/Interfaces.vala',
	'Docklets/Docklet.vala',
	'Docklets/DockletItem.vala',
	'Docklets/DockletManager.vala',
	'Drawing/Color.vala',
	'Drawing/DrawingService.vala',
	'Drawing/DockTheme.vala',
	'Drawing/Easing.vala',
	'Drawing/Renderer.vala',
	'Drawing/Surface.vala',
	'Drawing/SurfaceCache.vala',
	'Drawing/Theme.vala',
	'Factories/AbstractMain.vala',
	'Factories/Factory.vala',
	'Factories/ItemFactory.vala',
	'Items/ApplicationDockItem.vala',
	'Items/ApplicationDockItemProvider.vala',
	'Items/DefaultApplicationDockItemProvider.vala',
	'Items/DockContainer.vala',
	'Items/DockItem.vala',
	'Items/DockItemDrawValue.vala',
	'Items/DockItemProvider.vala',
	'Items/DockItemPreferences.vala',
	'Items/DockElement.vala',
	'Items/Enums.vala',
	'Items/FileDockItem.vala',
	'Items/PlaceholderDockItem.vala',
	'Items/PlankDockItem.vala',
	'Items/TransientDockItem.vala',
	'Services/Environment.vala',
	'Services/EnvironmentSettings.vala',
	'Services/Logger.vala',
	'Services/Paths.vala',
	'Services/Preferences.vala',
	'Services/Settings.vala',
	'Services/System.vala',
	'Services/Unity.vala',
	'Services/Worker.vala',
	'Widgets/CompositedWindow.vala',
	'Widgets/DockWindow.vala',
	'Widgets/HoverWindow.vala',
	'Widgets/PoofWindow.vala',
	'Widgets/PreferencesWindow.vala',
	'Widgets/TitledSeparatorMenuItem.vala',
]

plank_internal_lib_sources = [
	'InternalConsts.vala',
	'InternalQuarks.vala',
	'Services/Matcher.vala',
	'Services/WindowControl.vala',
	'Services/Utils.vala',
	'Widgets/DockletViewModel.vala',
	'gtk-compat.c',
	'gtk-compat.h',
]

plank_version_sources = configure_file(
	input: 'Version.vala.in',
	output: 'Version.vala',
	configuration: customconf,
)

plank_resources = gnome.compile_resources(
	'plank-resources',
	join_paths(meson.source_root(), 'data', 'plank.gresource.xml'),
	source_dir: join_paths(meson.source_root(), 'data'),
	c_name: 'plank',
)

plank_internal_lib = static_library(
	'plank-internal',
	plank_internal_lib_sources,
	dependencies: [plank_base_dep, wnck_x11_dep],
	install: false,
	c_args: '-fvisibility=internal',
	vala_args: [
		'--pkg', 'compat',
	],
)

plank_internal_dep = declare_dependency(link_with: [plank_internal_lib], include_directories: include_directories('.'))

plank_lib = shared_library(
	'plank',
	plank_lib_sources,
	plank_resources,
	plank_version_sources,
	dependencies: [plank_internal_dep, plank_base_dep, gmodule_dep, wnck_x11_dep, posix_dep, m_dep, xinput_dep, xfixes_dep],
	include_directories: config_inc_dir,
	install: true,
	install_dir: [true, join_paths(get_option('includedir'), 'plank'), true],
	soversion: '1.0.0',
	version : '1.0.0',
	vala_vapi: 'plank.vapi',
	vala_header: 'plank.h',
	vala_args: [
		'--gresources=' + join_paths(meson.source_root(), 'data', 'plank.gresource.xml'),
		'--pkg', 'config',
		'--pkg', 'compat',
	],
)

install_data('plank.deps', install_dir: join_paths(get_option('datadir'), 'vala', 'vapi'))

plank_dep = declare_dependency(link_with: [plank_lib], include_directories: include_directories('.'))

configure_file(
	input: 'plank.pc.in',
	output: 'plank.pc',
	configuration: pkgconf,
	install_dir: join_paths(get_option('libdir'), 'pkgconfig'),
)
