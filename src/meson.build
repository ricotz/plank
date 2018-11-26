plank_bin_sources = [
	'Main.vala',
]

plank_bin = executable(
	'plank',
	plank_bin_sources,
	dependencies: [plank_dep, plank_base_dep],
	include_directories: config_inc_dir,
	install: true,
	vala_args: [
		'--pkg', 'config',
	],
)
