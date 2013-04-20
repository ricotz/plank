distclean_dirs = \
	plank \
	gtk-doc \
	$(NULL)

phony_deps = \
	plank-doc \
	plank-gtk-doc \
	$(NULL)

plankdocdir=$(datadir)/devhelp/references/plank
plankimgdir=$(datadir)/devhelp/references/plank/img
plankgtkdocdir=$(datadir)/gtk-doc/html/plank

common_doc_files = \
	*.css \
	*.png \
	*.js \
	index.htm \
	*.html \
	$(NULL)

plankdoc_DATA = \
	plank/plank/plank.devhelp2 \
	$(addprefix plank/plank/,$(common_doc_files)) \
	$(NULL)

plankgtkdoc_DATA = gtk-doc/plank/html/*

plankimg_DATA = \
	plank/plank/img/*.png \
	$(NULL)

$(plankdoc_DATA) $(plankimg_DATA): plank-doc
$(plankgtkdoc_DATA): plank-gtk-doc

valadoc_flags = \
	--force \
	--verbose \
	--package-name $(PACKAGE_NAME) \
	--package-version $(PACKAGE_VERSION) \
	--target-glib=2.32 \
	$(NULL)

# plank documentation
plank_doc_files = \
	$(top_srcdir)/lib/DockController.vala \
	$(top_srcdir)/lib/DockPreferences.vala \
	$(top_srcdir)/lib/DockRenderer.vala \
	$(top_srcdir)/lib/DragManager.vala \
	$(top_srcdir)/lib/HideManager.vala \
	$(top_srcdir)/lib/PositionManager.vala \
	$(top_srcdir)/lib/Drawing/AnimatedRenderer.vala \
	$(top_srcdir)/lib/Drawing/Color.vala \
	$(top_srcdir)/lib/Drawing/DrawingService.vala \
	$(top_srcdir)/lib/Drawing/DockSurface.vala \
	$(top_srcdir)/lib/Drawing/DockTheme.vala \
	$(top_srcdir)/lib/Drawing/HoverTheme.vala \
	$(top_srcdir)/lib/Drawing/Theme.vala \
	$(top_srcdir)/lib/Factories/AbstractMain.vala \
	$(top_srcdir)/lib/Factories/Factory.vala \
	$(top_srcdir)/lib/Factories/ItemFactory.vala \
	$(top_srcdir)/lib/Items/ApplicationDockItem.vala \
	$(top_srcdir)/lib/Items/ApplicationDockItemProvider.vala \
	$(top_srcdir)/lib/Items/DockItem.vala \
	$(top_srcdir)/lib/Items/DockItemProvider.vala \
	$(top_srcdir)/lib/Items/DockItemPreferences.vala \
	$(top_srcdir)/lib/Items/FileDockItem.vala \
	$(top_srcdir)/lib/Items/PlankDockItem.vala \
	$(top_srcdir)/lib/Items/TransientDockItem.vala \
	$(top_srcdir)/lib/Services/Logger.vala \
	$(top_srcdir)/lib/Services/Paths.vala \
	$(top_srcdir)/lib/Services/Preferences.vala \
	$(top_srcdir)/lib/Services/System.vala \
	$(top_srcdir)/lib/Widgets/CompositedWindow.vala \
	$(top_srcdir)/lib/Widgets/DockWindow.vala \
	$(top_srcdir)/lib/Widgets/HoverWindow.vala \
	$(top_srcdir)/lib/Widgets/PoofWindow.vala \
	$(top_srcdir)/lib/Widgets/TitledSeparatorMenuItem.vala \
	$(NULL)

plank_doc_deps = \
	plank-internal \
	compat \
	$(GEE_DEPEND) \
	gio-unix-2.0 \
	gdk-x11-3.0 \
	gtk+-3.0 \
	libbamf3 \
	libwnck-3.0 \
	posix \
	x11 \
	$(NULL)

valadoc_flags_plank = \
	$(valadoc_flags) \
	$(addprefix --pkg=,$(plank_doc_deps)) \
	--vapidir=$(top_builddir)/lib \
	--vapidir=$(top_srcdir)/vapi \
	$(plank_doc_files) \
	$(NULL)

plank-doc: $(plank_doc_files)
	$(AM_V_GEN)$(VALADOC) \
		-o plank/ \
		--doclet=html \
		$(valadoc_flags_plank) \
		$(NULL)

plank-gtk-doc: $(plank_doc_files)
	$(AM_V_GEN)$(VALADOC) \
		-X -l -X $(top_builddir)/lib/.libs/libplank.so \
		-X $(top_builddir)/lib/plank.h \
		-o gtk-doc/plank \
		--doclet=gtkdoc \
		$(valadoc_flags_plank) \
		$(NULL)

.PHONY: $(phony_deps)

distclean-local: distclean-docs
distclean-docs:
	rm -rf $(distclean_dirs)

