help2man = find_program('help2man', required: false)
if help2man.found()
	plank_1 = custom_target('plank manpage',
		depends: plank_bin,
		input: 'plank.h2m',
		output: 'plank.1',
		command: [
			help2man, '--no-info', '--include=@INPUT@', '--output=@OUTPUT@', plank_bin.full_path()
		],
		build_by_default: true,
	)
endif

install_man('plank.1')
