VALAFLAGS = \
	--pkg gtk+-2.0 \
	--pkg libbamf \
	--pkg gio-unix-2.0 \
	--pkg unique-1.0 \
	--vapidir .. \
	$(NULL)

plankdir = $(bindir)

plank_PROGRAMS = \
	plank \
	$(NULL)

plank_CFLAGS = $(GTK_CFLAGS) $(BAMF_CFLAGS) $(UNIQUE_CFLAGS)
plank_LDADD = $(GTK_LIBS) $(BAMF_LIBS) $(UNIQUE_LIBS)
plank_SOURCES = \
	CompositedWindow.vala \
	DockItems.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	DockWindow.vala \
	HoverWindow.vala \
	Plank.vala \
	PlankSurface.vala \
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
