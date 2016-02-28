include $(top_srcdir)/Makefile.common

BUILT_SOURCES = \
	plank_vala_doc.stamp \
	$(NULL)

common_doc_files = \
	*.css \
	*.devhelp2 \
	*.html \
	*.png \
	$(NULL)

doc_DATA = \
	$(addprefix vala-doc/plank/,$(common_doc_files) index.htm *.js) \
	vala-doc/plank/img/*.png \
	$(NULL)

plank_doc_files = \
	$(top_srcdir)/lib/DBusManager.vala \
	$(top_srcdir)/lib/DockController.vala \
	$(top_srcdir)/lib/DockPreferences.vala \
	$(top_srcdir)/lib/DockRenderer.vala \
	$(top_srcdir)/lib/DragManager.vala \
	$(top_srcdir)/lib/HideManager.vala \
	$(top_srcdir)/lib/PositionManager.vala \
	$(top_builddir)/lib/Version.vala \
	$(top_srcdir)/lib/DBus/Client.vala \
	$(top_srcdir)/lib/DBus/Interfaces.vala \
	$(top_srcdir)/lib/Docklets/Docklet.vala \
	$(top_srcdir)/lib/Docklets/DockletItem.vala \
	$(top_srcdir)/lib/Docklets/DockletManager.vala \
	$(top_srcdir)/lib/Drawing/Color.vala \
	$(top_srcdir)/lib/Drawing/DrawingService.vala \
	$(top_srcdir)/lib/Drawing/DockTheme.vala \
	$(top_srcdir)/lib/Drawing/Easing.vala \
	$(top_srcdir)/lib/Drawing/Renderer.vala \
	$(top_srcdir)/lib/Drawing/Surface.vala \
	$(top_srcdir)/lib/Drawing/SurfaceCache.vala \
	$(top_srcdir)/lib/Drawing/Theme.vala \
	$(top_srcdir)/lib/Factories/AbstractMain.vala \
	$(top_srcdir)/lib/Factories/Factory.vala \
	$(top_srcdir)/lib/Factories/ItemFactory.vala \
	$(top_srcdir)/lib/Items/ApplicationDockItem.vala \
	$(top_srcdir)/lib/Items/ApplicationDockItemProvider.vala \
	$(top_srcdir)/lib/Items/DefaultApplicationDockItemProvider.vala \
	$(top_srcdir)/lib/Items/DockContainer.vala \
	$(top_srcdir)/lib/Items/DockElement.vala \
	$(top_srcdir)/lib/Items/DockItem.vala \
	$(top_srcdir)/lib/Items/DockItemDrawValue.vala \
	$(top_srcdir)/lib/Items/DockItemProvider.vala \
	$(top_srcdir)/lib/Items/DockItemPreferences.vala \
	$(top_srcdir)/lib/Items/Enums.vala \
	$(top_srcdir)/lib/Items/FileDockItem.vala \
	$(top_srcdir)/lib/Items/PlaceholderDockItem.vala \
	$(top_srcdir)/lib/Items/PlankDockItem.vala \
	$(top_srcdir)/lib/Items/TransientDockItem.vala \
	$(top_srcdir)/lib/Services/Environment.vala \
	$(top_srcdir)/lib/Services/EnvironmentSettings.vala \
	$(top_srcdir)/lib/Services/Logger.vala \
	$(top_srcdir)/lib/Services/Paths.vala \
	$(top_srcdir)/lib/Services/Preferences.vala \
	$(top_srcdir)/lib/Services/Settings.vala \
	$(top_srcdir)/lib/Services/System.vala \
	$(top_srcdir)/lib/Services/Unity.vala \
	$(top_srcdir)/lib/Services/Worker.vala \
	$(top_srcdir)/lib/Widgets/CompositedWindow.vala \
	$(top_srcdir)/lib/Widgets/DockWindow.vala \
	$(top_srcdir)/lib/Widgets/HoverWindow.vala \
	$(top_srcdir)/lib/Widgets/PoofWindow.vala \
	$(top_srcdir)/lib/Widgets/PreferencesWindow.vala \
	$(top_srcdir)/lib/Widgets/TitledSeparatorMenuItem.vala \
	$(NULL)

valadoc_flags_plank = \
	--force \
	--verbose \
	--package-name $(PACKAGE_NAME) \
	--package-version $(PACKAGE_VERSION) \
	$(PLANK_DOCS_VALAFLAGS) \
	--driver "`$(VALAC) --version`" \
	--pkg plank-internal \
	--pkg compat \
	--pkg config \
	--vapidir=$(top_builddir)/lib \
	--vapidir=$(top_srcdir)/vapi \
	$(NULL)

if HAVE_VALADOC

cdocs: plank_c_doc.stamp
plank_c_doc.stamp: $(plank_doc_files) $(top_builddir)/lib/plank-internal.vapi Makefile
	$(AM_V_GEN)$(VALADOC) \
		-X -l -X $(top_builddir)/lib/.libs/libplank.so \
		-X $(top_builddir)/lib/plank.h \
		-o c-doc/ \
		--doclet=gtkdoc \
		$(valadoc_flags_plank) \
		$(filter %.vala,$^)
	$(AM_V_at)touch $@

plank_vala_doc.stamp: $(plank_doc_files) $(top_builddir)/lib/plank-internal.vapi Makefile
	$(AM_V_GEN)$(VALADOC) \
		-o vala-doc/ \
		--doclet=devhelp \
		$(valadoc_flags_plank) \
		$(filter %.vala,$^)
	$(AM_V_at)touch $@

html: plank_web_doc.stamp
plank_web_doc.stamp: $(plank_doc_files) $(top_builddir)/lib/plank-internal.vapi Makefile
	$(AM_V_GEN)$(VALADOC) \
		-o web-doc/ \
		--doclet=html \
		$(valadoc_flags_plank) \
		$(filter %.vala,$^)
	$(AM_V_at)touch $@

EXTRA_DIST = \
	$(BUILT_SOURCES) \
	vala-doc/* \
	$(NULL)

DISTCLEANFILES = \
	plank_c_doc.stamp \
	plank_vala_doc.stamp \
	plank_web_doc.stamp \
	$(NULL)

endif

distclean-local: distclean-docs
distclean-docs:
	rm -rf c-doc vala-doc web-doc

