VAPIDIR = $(top_srcdir)/vapi

VALAFLAGS = \
	--thread \
	$(PLANK_CORE_VALA_PKGS) \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

plankdir = $(bindir)

plank_PROGRAMS = \
	plank \
	$(NULL)

plank_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	$(NULL)
	
plank_LDADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

plank_VALASOURCES = \
	DockItems.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	HideManager.vala \
	Plank.vala \
	Drawing/AnimatedRenderer.vala \
	Drawing/Color.vala \
	Drawing/DrawingService.vala \
	Drawing/DockSurface.vala \
	Drawing/DockThemeRenderer.vala \
	Drawing/ThemeRenderer.vala \
	Factories/AbstractMain.vala \
	Factories/Factory.vala \
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
	Widgets/TitledSeparator.vala \
	$(NULL)

GENERATED_C_FILES = $(plank_VALASOURCES:.vala=.c)
plank_SOURCES = $(plank_VALASOURCES:.vala=.c)

$(GENERATED_C_FILES): plank_vala.stamp

plank_vala.stamp: $(addprefix $(srcdir)/,$(plank_VALASOURCES))
	$(AM_V_VALA)$(VALAC) $(plank_VALAFLAGS) $(VALAFLAGS) -C $^
	$(AM_V_at)touch $@

CLEANFILES = $(GENERATED_C_FILES) plank_vala.stamp
EXTRA_DIST = $(plank_VALASOURCES)

# need to make sure the vala sources are rebuilt
dist-hook:
	rm -rf $(addprefix $(distdir)/,$(GENERATED_C_FILES) plank_vala.stamp)
