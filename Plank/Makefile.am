VAPIDIR = $(top_srcdir)/vapi

VALAFLAGS = \
	--pkg gtk+-${GTK_API_VERSION} \
	--pkg gconf-2.0 \
	--pkg bamf \
	--pkg gee-1.0 \
	--pkg gio-unix-2.0 \
	--pkg unique-1.0 \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

plankdir = $(bindir)

plank_PROGRAMS = \
	plank \
	$(NULL)

plank_CFLAGS = $(PLANK_CORE_CFLAGS)
plank_LDADD = $(PLANK_CORE_LIBS)
plank_VALASOURCES = \
	CompositedWindow.vala \
	DockItems.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	DockWindow.vala \
	HoverWindow.vala \
	Plank.vala \
	PlankSurface.vala \
	PoofWindow.vala \
	ThemeRenderer.vala \
	Items/ApplicationDockItem.vala \
	Items/DockItem.vala \
	Items/DockItemPreferences.vala \
	Services/Drawing.vala \
	Services/Logger.vala \
	Services/Matcher.vala \
	Services/Paths.vala \
	Services/Preferences.vala \
	Services/System.vala \
	$(NULL)

GENERATED_C_FILES = $(plank_VALASOURCES:.vala=.c)
plank_SOURCES = $(plank_VALASOURCES:.vala=.c)

$(GENERATED_C_FILES): plank_vala.stamp

plank_vala.stamp: $(addprefix $(srcdir)/,$(plank_VALASOURCES))
	$(AM_V_VALA)$(VALAC) $(plank_VALAFLAGS) $(VALAFLAGS) -C $^
	$(AM_V_at)touch $@

DISTCLEANFILES = $(GENERATED_C_FILES) plank_vala.stamp
EXTRA_DIST = $(plank_VALASOURCES)

# need to make sure the vala sources are rebuilt
dist-hook:
	rm -rf $(addprefix $(distdir)/,$(GENERATED_C_FILES))
