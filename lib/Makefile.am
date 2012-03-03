include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

if USE_GTK2
SUFFIX=
lib_LTLIBRARIES = libplank.la
else
SUFFIX=3
lib_LTLIBRARIES = libplank3.la
endif

BUILT_SOURCES = libplank$(SUFFIX)_la_vala.stamp

libplankincludedir = $(includedir)/plank$(SUFFIX)
libplankinclude_HEADERS = plank$(SUFFIX).h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	plank$(SUFFIX).vapi \
	plank$(SUFFIX).deps \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libplank$(SUFFIX).pc

libplankdir = $(libdir)

libplank3_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-w \
	$(NULL)

libplank3_la_LDFLAGS = \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	-export-symbols $(builddir)/libplank$(SUFFIX).symbols \
	-lm \
	$(PLANK_CORE_LDFLAGS) \
	$(NULL)

libplank3_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	--vapidir $(VAPIDIR) \
	$(NULL)

libplank3_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libplank3_la_VALASOURCES = \
	DockController.vala \
	DockItems.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	HideManager.vala \
	PositionManager.vala \
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

libplank_la_valasource.stamp: $(libplank3_la_VALASOURCES)
	for f in $(filter %.vala,$^); do \
		cd $(abs_srcdir)/$$(dirname $$f); \
		if test \
			-f $$(basename $$f .vala).2.vala -a \
			! -L $$(basename $$f .vala).2.vala; then \
			rm $$(dirname $$f)/$$(basename $$f .vala).2.vala; fi; \
		if test \
			! -e $$(basename $$f .vala).2.vala; then \
			ln -s $$(basename $$f) $$(basename $$f .vala).2.vala; fi; \
	done
	$(AM_V_at)touch $@

libplank_la_VALASOURCES = \
	libplank_la_valasource.stamp \
	$(libplank3_la_VALASOURCES:.vala=.2.vala) \
	$(NULL)

libplank3_la_SOURCES = \
	libplank3_la_vala.stamp \
	$(libplank3_la_VALASOURCES:.vala=.c) \
	$(NULL)

plank3.h plank3.vapi: libplank3_la_vala.stamp

libplank_la_CFLAGS = $(libplank3_la_CFLAGS)
libplank_la_LDFLAGS = $(libplank3_la_LDFLAGS)
libplank_la_LIBADD = $(libplank3_la_LIBADD)
libplank_la_VALAFLAGS = \
	$(PLANK_CORE_2_VALAFLAGS) \
	--vapidir $(VAPIDIR) \
	$(NULL)

libplank_la_SOURCES = \
	libplank_la_vala.stamp \
	$(libplank_la_VALASOURCES:.vala=.c) \
	$(NULL)

plank.h plank.vapi: libplank_la_vala.stamp

libplank3_la_vala.stamp: $(libplank3_la_VALASOURCES)
	$(AM_V_VALA)$(VALAC) \
		$(libplank3_la_VALAFLAGS) \
		-C \
		-H plank3.h \
		--library plank3 \
		--symbols libplank3.symbols \
		--vapi plank3.vapi \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

libplank_la_vala.stamp: libplank_la_valasource.stamp $(libplank_la_VALASOURCES)
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
	libplank_la_valasource.stamp \
	$(libplank3_la_VALASOURCES) \
	libplank_la_vala.stamp \
	$(libplank_la_SOURCES) \
	plank.vapi \
	plank.h \
	libplank3_la_vala.stamp \
	$(libplank3_la_SOURCES) \
	plank3.vapi \
	plank3.h \
	$(NULL)

EXTRA_DIST = \
	libplank_la_valasource.stamp \
	$(libplank3_la_VALASOURCES) \
	$(libplank_la_VALASOURCES) \
	libplank.pc.in \
	libplank3.pc.in \
	plank.deps \
	plank.vapi \
	plank.h \
	plank3.deps \
	plank3.vapi \
	plank3.h \
	$(NULL)

