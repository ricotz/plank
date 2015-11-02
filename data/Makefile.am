NULL =

SUBDIRS = \
	icons \
	themes \
	$(NULL)

if ENABLE_APPORT
SUBDIRS += apport
endif

EXTRA_DIST = \
	application-default-icon.svg \
	plank.appdata.xml.in \
	net.launchpad.plank.gschema.xml.in.in \
	plank.desktop.in \
	plank.gresource.xml \
	poof.svg \
	ui/preferences.ui \
	$(NULL)

CLEANFILES = \
	plank.appdata.xml \
	plank.desktop \
	$(gsettings_SCHEMAS) \
	gschemas.compiled \
	net.launchpad.plank.gschema.valid \
	net.launchpad.plank.gschema.xml.in \
	$(NULL)

dist_man_MANS = \
	plank.1 \
	$(NULL)

applicationsdir = $(datadir)/applications
applications_DATA = plank.desktop

@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datadir)/appdata
appdata_DATA = plank.appdata.xml

gsettings_SCHEMAS = net.launchpad.plank.gschema.xml

@INTLTOOL_XML_RULE@

@GSETTINGS_RULES@

gschemas.compiled: Makefile $(gsettings_SCHEMAS:.xml=.valid)
	$(AM_V_GEN) $(GLIB_COMPILE_SCHEMAS) --targetdir=$(builddir) $(builddir)

all-local: gschemas.compiled

