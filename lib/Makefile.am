include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

libplankincludedir = $(includedir)/plank
libplankinclude_HEADERS = plank.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	plank.vapi \
	plank.deps \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libplank.pc

libplankdir = $(libdir)

BUILT_SOURCES = libplank_la_vala.stamp

lib_LTLIBRARIES = libplank.la

libplank_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-w \
	$(NULL)

libplank_la_LDFLAGS = \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)"
	$(PLANK_CORE_LDFLAGS) \
	$(NULL)

libplank_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	--vapidir $(VAPIDIR) \
	$(NULL)

libplank_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libplank_la_VALASOURCES = \
	DockController.vala \
	DockItems.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	DragManager.vala \
	HideManager.vala \
	Drawing/AnimatedRenderer.vala \
	Drawing/Color.vala \
	Drawing/DrawingService.vala \
	Drawing/DockSurface.vala \
	Drawing/DockThemeRenderer.vala \
	Drawing/HoverThemeRenderer.vala \
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

libplank_la_SOURCES = \
	libplank_la_vala.stamp \
	$(libplank_la_VALASOURCES:.vala=.c) \
	$(NULL)

plank.h plank.vapi: libplank_la_vala.stamp

libplank_la_vala.stamp: $(libplank_la_VALASOURCES)
	$(AM_V_VALA)$(VALAC) \
		$(libplank_la_VALAFLAGS) \
		-C \
		-H plank.h \
		--library plank \
		--symbols libplank.symbols \
		--vapi plank.vapi \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

DISTCLEANFILES = \
	$(libplank_la_SOURCES) \
	libplank_la_vala.stamp \
	plank.vapi \
	plank.h \
	$(NULL)

EXTRA_DIST = \
	$(libplank_la_VALASOURCES) \
	libplank.pc.in \
	$(NULL)

