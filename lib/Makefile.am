include $(top_srcdir)/Makefile.common

AM_CFLAGS = \
	$(COVERAGE_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	-include config.h \
	$(PLANK_CORE_CFLAGS) \
	$(NULL)

AM_VALAFLAGS = \
	$(COVERAGE_VALAFLAGS) \
	$(PLANK_CORE_VALAFLAGS) \
	--vapidir $(top_srcdir)/vapi \
	$(top_srcdir)/vapi/compat.vapi \
	$(top_srcdir)/vapi/config.vapi \
	--basedir $(srcdir) \
	--directory $(builddir) \
	-C \
	$(NULL)

BUILT_SOURCES = \
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
	$(COVERAGE_LDFLAGS) \
	$(LIBM) \
	$(builddir)/libplank-internal.la \
	$(NULL)

libplank_la_VALASOURCES = \
	DBusManager.vala \
	DockController.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	DragManager.vala \
	HideManager.vala \
	PositionManager.vala \
	DBus/Client.vala \
	DBus/Interfaces.vala \
	Docklets/Docklet.vala \
	Docklets/DockletItem.vala \
	Docklets/DockletManager.vala \
	Drawing/Color.vala \
	Drawing/DrawingService.vala \
	Drawing/DockTheme.vala \
	Drawing/Easing.vala \
	Drawing/Renderer.vala \
	Drawing/Surface.vala \
	Drawing/SurfaceCache.vala \
	Drawing/Theme.vala \
	Factories/AbstractMain.vala \
	Factories/Factory.vala \
	Factories/ItemFactory.vala \
	Items/ApplicationDockItem.vala \
	Items/ApplicationDockItemProvider.vala \
	Items/DefaultApplicationDockItemProvider.vala \
	Items/DockContainer.vala \
	Items/DockItem.vala \
	Items/DockItemDrawValue.vala \
	Items/DockItemProvider.vala \
	Items/DockItemPreferences.vala \
	Items/DockElement.vala \
	Items/Enums.vala \
	Items/FileDockItem.vala \
	Items/PlaceholderDockItem.vala \
	Items/PlankDockItem.vala \
	Items/TransientDockItem.vala \
	Services/Environment.vala \
	Services/EnvironmentSettings.vala \
	Services/Logger.vala \
	Services/Paths.vala \
	Services/Preferences.vala \
	Services/Settings.vala \
	Services/System.vala \
	Services/Unity.vala \
	Services/Worker.vala \
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

plank-resources.c: $(top_srcdir)/data/plank.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(top_srcdir)/data $(top_srcdir)/data/plank.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(top_srcdir)/data --generate --c-name plank $<

plank.h plank.vapi: libplank_la_vala.stamp
$(libplank_la_VALASOURCES:.vala=.c): libplank_la_vala.stamp

libplank_la_vala.stamp build-abi: libplank_internal_la_vala.stamp $(libplank_la_VALASOURCES) $(libplank_la_BUILT_VALASOURCES) Makefile
	$(AM_V_VALA)$(VALAC) \
		$(AM_VALAFLAGS) $(libplank_la_VALAFLAGS) \
		-H plank.h \
		--library plank \
		--symbols build-abi \
		--vapi plank.vapi \
		--gresources $(top_srcdir)/data/plank.gresource.xml \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

symbols: build-abi
	@cat $(builddir)/build-abi | sort > $(srcdir)/libplank.symbols


noinst_LTLIBRARIES = libplank-internal.la

libplank_internal_la_CFLAGS = \
	$(AM_CFLAGS) \
	-fPIC \
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
	InternalConsts.vala \
	InternalQuarks.vala \
	Services/Matcher.vala \
	Services/WindowControl.vala \
	Services/Utils.vala \
	Widgets/DockletViewModel.vala \
	$(NULL)

libplank_internal_la_SOURCES = \
	gtk-compat.c \
	gtk-compat.h \
	$(NULL)

nodist_libplank_internal_la_SOURCES = \
	$(libplank_internal_la_VALASOURCES:.vala=.c) \
	$(NULL)

plank-internal.h plank-internal.vapi: libplank_internal_la_vala.stamp
$(libplank_internal_la_VALASOURCES:.vala=.c): libplank_internal_la_vala.stamp

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
	libplank_la_vala.stamp \
	libplank_internal_la_vala.stamp \
	$(nodist_libplank_la_SOURCES) \
	$(nodist_libplank_internal_la_SOURCES) \
	build-abi \
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
	plank.deps \
	plank.pc.in \
	Version.vala.in \
	$(NULL)

