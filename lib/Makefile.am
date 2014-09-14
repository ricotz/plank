include $(top_srcdir)/Makefile.common

AM_CFLAGS = \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	-include config.h \
	$(PLANK_CORE_CFLAGS) \
	-w \
	$(NULL)

AM_LDFLAGS = \
	$(LIBM) \
	$(NULL)

AM_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	--vapidir $(top_srcdir)/vapi \
	$(top_srcdir)/vapi/compat.vapi \
	$(top_srcdir)/vapi/config.vapi \
	--basedir $(srcdir) \
	--directory $(builddir) \
	-C \
	$(NULL)

BUILT_SOURCES = \
	libplank_internal_la_vala.stamp \
	libplank_la_vala.stamp \
	plank.h \
	plank-resources.c \
	$(NULL)

libplankincludedir = $(includedir)/plank
nodist_libplankinclude_HEADERS = plank.h

vapidir = $(datadir)/vala/vapi
nodist_vapi_DATA = \
	plank.vapi \
	plank.deps \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
nodist_pkgconfig_DATA = plank.pc


lib_LTLIBRARIES = libplank.la

libplank_la_LDFLAGS = \
	$(AM_LDLAGS) \
	-no-undefined \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	-export-dynamic \
	-export-symbols-regex '^plank_.*' \
	$(NULL)

libplank_la_VALAFLAGS = \
	$(builddir)/plank-internal.vapi \
	$(NULL)

libplank_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(builddir)/libplank-internal.la \
	$(NULL)

libplank_la_VALASOURCES = \
	DockController.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	DragManager.vala \
	HideManager.vala \
	PositionManager.vala \
	Drawing/AnimatedRenderer.vala \
	Drawing/Color.vala \
	Drawing/DrawingService.vala \
	Drawing/DockSurface.vala \
	Drawing/DockTheme.vala \
	Drawing/Theme.vala \
	Factories/AbstractMain.vala \
	Factories/Factory.vala \
	Factories/ItemFactory.vala \
	Items/ApplicationDockItem.vala \
	Items/ApplicationDockItemProvider.vala \
	Items/DefaultApplicationDockItemProvider.vala \
	Items/DockContainer.vala \
	Items/DockItem.vala \
	Items/DockItemProvider.vala \
	Items/DockItemPreferences.vala \
	Items/DockElement.vala \
	Items/FileDockItem.vala \
	Items/PlaceholderDockItem.vala \
	Items/PlankDockItem.vala \
	Items/TransientDockItem.vala \
	Services/Logger.vala \
	Services/Paths.vala \
	Services/Preferences.vala \
	Services/System.vala \
	Widgets/CompositedWindow.vala \
	Widgets/DockWindow.vala \
	Widgets/HoverWindow.vala \
	Widgets/PoofWindow.vala \
	Widgets/PreferencesWindow.vala \
	Widgets/TitledSeparatorMenuItem.vala \
	$(NULL)

libplank_la_BUILT_VALASOURCES = \
	Version.vala \
	$(NULL)

nodist_libplank_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libplank_la_BUILT_VALASOURCES:.vala=.c) \
	$(libplank_la_VALASOURCES:.vala=.c) \
	$(NULL)

plank-resources.c: plank.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(top_srcdir)/data $(srcdir)/plank.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(top_srcdir)/data --generate --c-name plank $<

plank.h plank.vapi: libplank_la_vala.stamp

libplank_la_vala.stamp build-abi: libplank_internal_la_vala.stamp $(libplank_la_VALASOURCES) $(libplank_la_BUILT_VALASOURCES) Makefile
	$(AM_V_VALA)$(VALAC) \
		$(AM_VALAFLAGS) $(libplank_la_VALAFLAGS) \
		-H plank.h \
		--library plank \
		--symbols build-abi \
		--vapi plank.vapi \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

symbols: build-abi
	@cat $(builddir)/build-abi | sort > $(srcdir)/libplank.symbols


noinst_LTLIBRARIES = libplank-internal.la

libplank_internal_la_CFLAGS = \
	$(AM_CFLAGS) \
	-fvisibility=internal \
	$(NULL)

libplank_internal_la_LDFLAGS = \
	-avoid-version \
	-non_shared \
	-static \
	$(NULL)

libplank_internal_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libplank_internal_la_VALASOURCES = \
	Services/Matcher.vala \
	Services/WindowControl.vala \
	$(NULL)

nodist_libplank_internal_la_SOURCES = \
	$(libplank_internal_la_VALASOURCES:.vala=.c) \
	$(NULL)

plank-internal.h plank-internal.vapi: libplank_internal_la_vala.stamp

libplank_internal_la_vala.stamp: $(libplank_internal_la_VALASOURCES) Makefile
	$(AM_V_VALA)$(VALAC) \
		$(AM_VALAFLAGS) \
		-H plank-internal.h \
		--library plank-internal \
		--vapi plank-internal.vapi \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@


TESTS = abicheck.sh

CLEANFILES = \
	$(nodist_libplank_la_SOURCES) \
	$(nodist_libplank_internal_la_SOURCES) \
	build-abi \
	plank.deps \
	plank.pc \
	plank.vapi \
	plank.h \
	plank-internal.vapi \
	plank-internal.h \
	Version.vala \
	$(NULL)

EXTRA_DIST = \
	$(libplank_la_VALASOURCES) \
	$(libplank_internal_la_VALASOURCES) \
	abicheck.sh \
	libplank.symbols \
	plank.deps.in \
	plank.gresource.xml \
	plank.pc.in \
	Version.vala.in \
	$(NULL)

