NULL =

SUBDIRS = \
	icons \
	themes \
	$(NULL)

if ENABLE_APPORT
SUBDIRS += apport
endif

EXTRA_DIST = \
	plank.desktop.in \
	poof.png \
	$(NULL)

CLEANFILES = \
	plank.desktop \
	$(NULL)

dist_man_MANS = \
	plank.1 \
	$(NULL)

applicationsdir = $(datadir)/applications
applications_DATA = plank.desktop

@INTLTOOL_DESKTOP_RULE@
