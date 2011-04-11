VAPIDIR = $(top_srcdir)/vapi

LIB_CURRENT=0
LIB_REVISION=0
LIB_AGE=0
LIB_VERSION_INFO="$(LIB_CURRENT):$(LIB_REVISION):$(LIB_AGE)"

#lib_LTLIBRARIES = libplank.la
noinst_LTLIBRARIES = libplank.la

libplankdir = $(bindir)

libplank_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-w \
	$(NULL)

libplank_la_LDFLAGS = \
	-version-info $(LIB_VERSION_INFO) \
	$(PLANK_CORE_LDFLAGS) \
	$(NULL)

libplank_la_VALAFLAGS = \
	--thread \
	$(PLANK_CORE_VALA_PKGS) \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

libplank_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libplank_la_VALASOURCES = \
	DockItems.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	HideManager.vala \
	Drawing/AnimatedRenderer.vala \
	Drawing/Color.vala \
	Drawing/DrawingService.vala \
	Drawing/DockSurface.vala \
	Drawing/DockThemeRenderer.vala \
	Drawing/ThemeRenderer.vala \
	Factories/AbstractMain.vala \
	Factories/Factory.vala \
	Factories/ItemFactory.vala \
	Items/ApplicationDockItem.vala \
	Items/DockItem.vala \
	Items/DockItemPreferences.vala \
	Items/FileDockItem.vala \
	Items/PlankDockItem.vala \
	Items/TransientDockItem.vala \
	Services/Logger.vala \
	Services/Matcher.vala \
	Services/Paths.vala \
	Services/Preferences.vala \
	Services/System.vala \
	Services/WindowControl.vala \
	Widgets/CompositedWindow.vala \
	Widgets/DockWindow.vala \
	Widgets/HoverWindow.vala \
	Widgets/PoofWindow.vala \
	Widgets/TitledSeparatorMenuItem.vala \
	$(NULL)

libplank_la_SOURCES = $(libplank_la_VALASOURCES:.vala=.c)

$(libplank_la_SOURCES): libplank_la_vala.stamp

plank.vapi libplank_la_vala.stamp: $(libplank_la_VALASOURCES) Makefile
	$(AM_V_VALA)$(VALAC) $(libplank_la_VALAFLAGS) -C -H plank.h --library plank $(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

DISTCLEANFILES = \
	$(libplank_la_SOURCES) \
	libplank_la_vala.stamp \
	plank.vapi \
	plank.h \
	$(NULL)

EXTRA_DIST = \
	$(libplank_la_VALASOURCES) \
	$(NULL)

#dist-hook:
#	rm -rf $(addprefix $(distdir)/,	$(libplank_la_SOURCES) libplank_la_vala.stamp)
