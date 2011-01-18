VALAFLAGS = \
	--pkg gtk+-2.0 \
	--pkg gconf-2.0 \
	--pkg libbamf \
	--pkg gee-1.0 \
	--pkg gio-unix-2.0 \
	--pkg unique-1.0 \
	--vapidir .. \
	Build.vapi \
	$(NULL)

plankdir = $(bindir)

plank_PROGRAMS = \
	plank \
	$(NULL)

plank_CFLAGS = $(GTK_CFLAGS) $(GEE_CFLAGS) $(GCONF_CFLAGS) $(BAMF_CFLAGS) $(UNIQUE_CFLAGS)
plank_LDADD = $(GTK_LIBS) $(GEE_LIBS) $(GCONF_LIBS) $(BAMF_LIBS) $(UNIQUE_LIBS)
plank_SOURCES = \
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
