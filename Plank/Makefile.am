VALAFLAGS = \
	--pkg gtk+-2.0 \
	--pkg libbamf \
	--vapidir .. \
	$(NULL)

plankdir = $(bindir)

plank_PROGRAMS = \
	plank \
	$(NULL)

plank_CFLAGS = $(GTK_CFLAGS) $(BAMF_CFLAGS)
plank_LDADD = $(GTK_LIBS) $(BAMF_LIBS)
plank_SOURCES = \
	CompositedWindow.vala \
	DockItems.vala \
	DockPreferences.vala \
	DockRenderer.vala \
	DockWindow.vala \
	Plank.vala \
	PlankSurface.vala \
	Items/ApplicationDockItem.vala \
	Items/DockItem.vala \
	Items/DockItemPreferences.vala \
	Services/Drawing.vala \
	Services/Logger.vala \
	Services/Matcher.vala \
	Services/Paths.vala \
	Services/Preferences.vala \
	$(NULL)
