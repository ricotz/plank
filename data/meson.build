plank_appdata = i18n.merge_file(
	input: 'plank.appdata.xml.in',
	output: 'plank.appdata.xml',
	po_dir: '../po',
	type: 'xml',
	install: true,
	install_dir: join_paths(data_dir, 'metainfo')
)

plank_gschema = configure_file(
	input: 'net.launchpad.plank.gschema.xml.in',
	output: 'net.launchpad.plank.gschema.xml',
	configuration: customconf,
	install: true,
	install_dir: join_paths(data_dir, 'glib-2.0', 'schemas')
)

plank_gschema_compile = gnome.compile_schemas(
	depend_files: plank_gschema,
)

i18n.merge_file(
	input: 'plank.desktop.in',
	output: 'plank.desktop',
	po_dir: '../po',
	type: 'desktop',
	install: true,
	install_dir: join_paths(data_dir, 'applications')
)

icons_dir = join_paths(get_option('datadir'), 'icons', 'hicolor')
foreach size : ['16x16', '22x22', '24x24', '32x32', '48x48', '64x64', '128x128']
	install_data(join_paths('icons', size, 'plank.svg'), install_dir: join_paths(icons_dir, size, 'apps'))
endforeach

themes_dir = join_paths(pkgdata_dir, 'themes')
foreach theme : ['Default', 'Matte', 'Transparent']
	install_subdir(join_paths('themes', theme), install_dir: themes_dir)
endforeach

# Installation of Apport support files
enable_apport = get_option('enable-apport')
if enable_apport
	install_data('apport/source_plank.py', install_dir: join_paths(get_option('datadir'), 'apport', 'package-hooks'))
	install_data('apport/plank-crashdb.conf', install_dir: join_paths(get_option('sysconfdir'), 'apport', 'crashdb.conf.d'))
endif
