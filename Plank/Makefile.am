VAPIDIR = $(top_srcdir)/vapi

VALAFLAGS = \
	--pkg gtk+-${GTK_API_VERSION} \
	--pkg gconf-2.0 \
	--pkg bamf \
	--pkg libwnck-1.0 \
	--pkg gee-1.0 \
	--pkg gio-unix-2.0 \
	--pkg unique-1.0 \
	--pkg x11 \
	--pkg gdk-x11-2.0 \
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
	Plank.vala \
	Drawing/Color.vala \
	Drawing/DrawingService.vala \
	Drawing/DockSurface.vala \
	Drawing/DockThemeRenderer.vala \
	Drawing/ThemeRenderer.vala \
	Items/ApplicationDockItem.vala \
	Items/DockItem.vala \
	Items/DockItemPreferences.vala \
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
