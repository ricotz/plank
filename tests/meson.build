tests_bin_sources = [
	'Controller.vala',
	'Drawing.vala',
	'Items.vala',
	'Main.vala',
	'Preferences.vala',
	'TestHelper.vala',
	'Widgets.vala',
]

tests_bin = executable(
	'tests',
	tests_bin_sources,
	'test-config.vapi',
	dependencies: [plank_dep, plank_internal_dep, plank_base_dep, wnck_x11_dep],
	c_args: [
		'-DTEST_DATA_DIR="@0@/tests/data"'.format(meson.source_root()),
		'-DTEST_HOME_DIR="@0@/tests/home"'.format(meson.build_root()),
	],
)

dock_bin_sources = [
	'Dock.vala',
]

dock_bin = executable(
	'dock',
	dock_bin_sources,
	'test-config.vapi',
	plank_gschema_compile,
	dependencies: [plank_dep, plank_base_dep],
)

test_env = [
	'HOME=@0@/tests/home'.format(meson.build_root()),
	'GSETTINGS_SCHEMA_DIR=@0@/data'.format(meson.build_root()),
	'PLANK_DOCKLET_DIRS=@0@/docklets'.format(meson.build_root()),
	# Headless: $(XVFB_RUN) --auto-servernum --server-args="-screen 0 1280x1024x24" $(DBUS_LAUNCH)
]

test('tests', tests_bin,
	# Run with gtester --verbose --keep-going -o=$(builddir)/test-report.xml $(builddir)/tests
	#  mesontest --wrap="gtester --verbose --keep-going" tests
	env: test_env,
	is_parallel: false,
)

test('dock', dock_bin,
	args: ['-n', 'test1'],
	env: test_env,
	is_parallel: false,
)
