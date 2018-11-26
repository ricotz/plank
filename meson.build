project('plank',
	'c', 'vala',
	version: '0.11.89',
	meson_version: '>= 0.42.1',
	license: 'GPL3',
)

is_release = false

gnome = import('gnome')
i18n = import('i18n')
cc = meson.get_compiler('c')

plank_version = meson.project_version()
version_array = plank_version.split('.')

vala_version_required = '0.34.0'
vala = meson.get_compiler('vala')
if not vala.version().version_compare('>= @0@'.format(vala_version_required))
	error('Valac >= @0@ required!'.format(vala_version_required))
endif


data_dir = join_paths(get_option('prefix'), get_option('datadir'))
docklets_dir = join_paths(get_option('prefix'), get_option('libdir'), 'plank', 'docklets')
pkgdata_dir = join_paths(get_option('prefix'), get_option('datadir'), 'plank')
pkglib_dir = join_paths(get_option('prefix'), get_option('libdir'), 'plank')

config_inc_dir = include_directories('.')

conf = configuration_data()
conf.set_quoted('PACKAGE', meson.project_name())
conf.set_quoted('PACKAGE_BUGREPORT', 'https://bugs.launchpad.net/plank')
conf.set_quoted('PACKAGE_NAME', meson.project_name())
conf.set_quoted('PACKAGE_STRING', 'Plank')
conf.set_quoted('PACKAGE_TARNAME', meson.project_name())
conf.set_quoted('PACKAGE_URL', 'https://launchpad.net/plank')
conf.set_quoted('PACKAGE_VERSION', plank_version)
conf.set_quoted('DATADIR', data_dir)
conf.set_quoted('PKGDATADIR', pkgdata_dir)
conf.set_quoted('PKGLIBDIR', pkglib_dir)
conf.set_quoted('DOCKLETSDIR', docklets_dir)
conf.set_quoted('RELEASE_NAME', 'Stupidly simple.')
conf.set_quoted('VERSION', plank_version)
conf.set_quoted('VERSION_INFO', (is_release ? 'Release' : 'Development'))
conf.set_quoted('BUILD_VERSION', plank_version)
conf.set('VERSION_MAJOR', version_array[0])
conf.set('VERSION_MINOR', version_array[1])
conf.set('VERSION_MICRO', version_array[2])
conf.set('VERSION_NANO', (version_array.length() > 3 ? version_array[3] : 0))
configure_file(input: 'config.h.meson', output: 'config.h', configuration: conf)

customconf = configuration_data()
customconf.set('GETTEXT_PACKAGE', meson.project_name())
customconf.set('PLANK_MAJOR_VERSION', version_array[0])
customconf.set('PLANK_MINOR_VERSION', version_array[1])
customconf.set('PLANK_MICRO_VERSION', version_array[2])
customconf.set('PLANK_NANO_VERSION', (version_array.length() > 3 ? version_array[3] : 0))

pkgconf = configuration_data()
pkgconf.set('PACKAGE_VERSION', plank_version)
pkgconf.set('prefix', get_option('prefix'))
pkgconf.set('exec_prefix', '${prefix}')
pkgconf.set('libdir', '${prefix}/@0@'.format(get_option('libdir')))
pkgconf.set('bindir', '${exec_prefix}/@0@'.format(get_option('bindir')))
pkgconf.set('datarootdir', '${prefix}/@0@'.format(get_option('datadir')))
pkgconf.set('datadir', '${datarootdir}')
pkgconf.set('includedir', '${prefix}/@0@'.format(get_option('includedir')))


add_project_arguments([
		'--target-glib=2.40',
		'--hide-internal',
		'--enable-deprecated',
		'--vapidir=' + join_paths(meson.source_root(), 'vapi'),
	],
	language: 'vala',
)
add_project_arguments([
		'-Wno-discarded-qualifiers',
		'-Wno-incompatible-pointer-types',
		'-Wno-unused',
		'-Wl,--enable-new-dtags',

		'-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
		'-DGMENU_I_KNOW_THIS_IS_UNSTABLE',
		'-DWNCK_I_KNOW_THIS_IS_UNSTABLE',

		'-DGLIB_VERSION_MIN_REQUIRED=GLIB_VERSION_2_40',
		'-DGLIB_VERSION_MAX_ALLOWED=GLIB_VERSION_2_40',
		'-DGDK_VERSION_MIN_REQUIRED=GDK_VERSION_3_10',
		'-DGDK_VERSION_MAX_ALLOWED=GDK_VERSION_3_10',
	],
	language: 'c',
)


# Dependencies
glib_version_required = '2.40.0'
gtk_version_required = '3.10.0'
gdk_pixbuf_version_required = '2.26.0'
bamf_version_required = '0.4.0'
cairo_version_required = '1.13'

gio_dep = [dependency('gio-2.0', version: '>= @0@'.format(glib_version_required)), dependency('gio-unix-2.0')]
gmodule_dep = dependency('gmodule-2.0', version: '>= @0@'.format(glib_version_required))
gtk_dep = [dependency('gtk+-3.0', version: '>= @0@'.format(gtk_version_required)), dependency('gdk-x11-3.0')]
gdk_pixbuf_dep = dependency('gdk-pixbuf-2.0', version: '>= @0@'.format(gdk_pixbuf_version_required))
gee_dep = dependency('gee-0.8')
bamf_dep = dependency('libbamf3', version: '>= @0@'.format(bamf_version_required))
cairo_dep = dependency('cairo',  version: '>= @0@'.format(cairo_version_required))
wnck_x11_dep = [dependency('libwnck-3.0'), dependency('x11')]
gnomemenu_dep = dependency('libgnome-menu-3.0')
posix_dep = vala.find_library('posix')
m_dep = cc.find_library('m', required: false)

plank_base_dep = [gio_dep, gee_dep, gtk_dep, bamf_dep]

# Support dynamic quicklists provided with dbusmenu
enable_dbusmenu = get_option('enable-dbusmenu')
if enable_dbusmenu != 'no'
	want_dbusmenu = (enable_dbusmenu == 'yes')
	dbusmenu_glib_dep = dependency('dbusmenu-glib-0.4', required: false)
	dbusmenu_gtk_dep = dependency('dbusmenu-gtk3-0.4', required: false)
	if dbusmenu_glib_dep.found() and dbusmenu_gtk_dep.found()
		# TODO See https://github.com/mesonbuild/meson/issues/1195
		#add_project_arguments('--define', 'HAVE_DBUSMENU', '--pkg', 'Dbusmenu-0.4', '--pkg', 'DbusmenuGtk3-0.4', language: 'vala')
	elif want_dbusmenu
		error('No dbusmenu support possible which was explicitly requested.')
	endif
else
	dbusmenu_glib_dep = []
	dbusmenu_gtk_dep = []
endif

# Support barrier-supported unhiding using Xinput 2.3
enable_barriers = get_option('enable-barriers')
if enable_barriers != 'no'
	want_barriers = (enable_barriers == 'yes')
	xinput_dep = dependency('xi', required: false)
	xfixes_dep = dependency('xfixes', required: false)
	if cc.has_function('XIBarrierReleasePointer', dependencies: xinput_dep) and cc.has_function('XFixesDestroyPointerBarrier', dependencies: xfixes_dep)
		add_project_arguments('--define', 'HAVE_BARRIERS', '--pkg', 'xi', '--pkg', 'xfixes', language: 'vala')
	elif want_barriers
		error('No barriers support possible which was explicitly requested.')
	endif
else
	xinput_dep = []
	xfixes_dep = []
endif

# Run checks and add build-flags to e.g. differenciate between Linux and BSD
if cc.has_header('sys/prctl.h')
	add_project_arguments('--define', 'HAVE_SYS_PRCTL_H', language: 'vala')
endif

# Enable output of benchmarking data
enable_benchmark = get_option('enable-benchmark')
if enable_benchmark
	add_project_arguments('--define', 'BENCHMARK', language: 'vala')
endif


subdir('data')
subdir('po')
subdir('lib')
subdir('src')
subdir('docklets')
subdir('examples')
subdir('tests')
subdir('docs')
