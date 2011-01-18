SUBDIRS = icons

EXTRA_DIST = plank.desktop.in \
	poof.png

CLEANFILES = plank.desktop

applicationsdir = $(datadir)/applications
applications_DATA = plank.desktop

startupdir = $(sysconfdir)/xdg/autostart
startup_DATA = plank.desktop

resourcedir = $(datadir)/plank
dist_resource_DATA = poof.png

@INTLTOOL_DESKTOP_RULE@
