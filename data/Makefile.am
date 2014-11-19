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
	plank.desktop.in \
	poof.png \
	ui/preferences.ui \
	$(NULL)

CLEANFILES = \
	plank.appdata.xml \
	plank.desktop \
	$(NULL)

dist_man_MANS = \
	plank.1 \
	$(NULL)

applicationsdir = $(datadir)/applications
applications_DATA = plank.desktop

@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datadir)/appdata
appdata_DATA = plank.appdata.xml

@INTLTOOL_XML_RULE@
