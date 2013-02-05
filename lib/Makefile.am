include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

lib_LTLIBRARIES = libplank.la

BUILT_SOURCES = \
	libplank_la_vala.stamp \
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

libplankdir = $(libdir)

libplank_la_CFLAGS = \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-w \
	$(NULL)

libplank_la_LDFLAGS = \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	-export-symbols $(builddir)/build-abi \
	-lm \
	$(PLANK_CORE_LDFLAGS) \
	$(NULL)

libplank_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/compat.vapi \
	$(NULL)

libplank_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
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
	Drawing/HoverTheme.vala \
	Drawing/Theme.vala \
	Factories/AbstractMain.vala \
	Factories/Factory.vala \
	Factories/ItemFactory.vala \
	Items/ApplicationDockItem.vala \
	Items/ApplicationDockItemProvider.vala \
	Items/DockItem.vala \
	Items/DockItemProvider.vala \
	Items/DockItemPreferences.vala \
	Items/FileDockItem.vala \
	Items/PlankDockItem.vala \
	Items/TransientDockItem.vala \
	Services/Logger.vala \
	Services/Matcher.vala \
	Services/Paths.vala \
	Services/Preferences.vala \
	Services/System.vala \
	Services/Unity.vala \
	Services/WindowControl.vala \
	Widgets/CompositedWindow.vala \
	Widgets/DockWindow.vala \
	Widgets/HoverWindow.vala \
	Widgets/PoofWindow.vala \
	Widgets/TitledSeparatorMenuItem.vala \
	$(NULL)

nodist_libplank_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libplank_la_VALASOURCES:.vala=.c) \
	$(NULL)

plank-resources.c: plank.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(top_srcdir)/data $(srcdir)/plank.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(top_srcdir)/data --generate --c-name plank $<

plank.h plank.vapi: libplank_la_vala.stamp

plank.deps: Makefile
	@echo Creating $@
	@touch $@
	@cp $(srcdir)/plank.deps.in $@
if HAVE_DBUSMENU
	@echo "Dbusmenu-0.4" >> $@
	@echo "DbusmenuGtk3-0.4" >> $@
endif

libplank_la_vala.stamp build-abi: $(libplank_la_VALASOURCES)
	$(AM_V_VALA)$(VALAC) \
		$(libplank_la_VALAFLAGS) \
		--basedir $(srcdir) \
		--directory $(builddir) \
		-C \
		-H plank.h \
		--library plank \
		--symbols build-abi \
		--vapi plank.vapi \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

symbols: build-abi
	@cat $(builddir)/build-abi | sort > $(srcdir)/libplank.symbols

TESTS = abicheck.sh

CLEANFILES = \
	$(nodist_libplank_la_SOURCES) \
	build-abi \
	plank.deps \
	plank.pc \
	plank.vapi \
	plank.h \
	$(NULL)

EXTRA_DIST = \
	$(libplank_la_VALASOURCES) \
	abicheck.sh \
	libplank.symbols \
	plank.deps.in \
	plank.gresource.xml \
	plank.pc.in \
	$(NULL)

