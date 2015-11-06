include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

BUILT_SOURCES = \
	docky-desktop-resources.c \
	$(NULL)

libdocklet_desktop_la_LTLIBRARIES = libdocklet-desktop.la

libdocklet_desktop_ladir = $(pkglibdir)/docklets

libdocklet_desktop_la_VALASOURCES = \
	DesktopDockItem.vala \
	DesktopDocklet.vala \
	$(NULL)

nodist_libdocklet_desktop_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libdocklet_desktop_la_VALASOURCES:.vala=.c) \
	$(NULL)

libdocklet_desktop_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(VAPIDIR)/config.vapi \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_builddir)/lib \
	--pkg plank \
	$(NULL)

libdocklet_desktop_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libdocklet_desktop_la_LDFLAGS = \
	$(DOCKLET_LDFLAGS) \
	$(PLANK_CORE_LDFLAGS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

libdocklet_desktop_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	-include config.h -w \
	-I$(top_builddir)/lib \
	$(NULL)

docky-desktop-resources.c: $(srcdir)/desktop.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(srcdir) $(srcdir)/desktop.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(srcdir) --generate --c-name docky_desktop $<

$(libdocklet_desktop_la_VALASOURCES:.vala=.c): libdocklet_desktop_la_vala.stamp

libdocklet_desktop_la_vala.stamp: $(libdocklet_desktop_la_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libdocklet_desktop_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	libdocklet_desktop_la_vala.stamp \
	$(nodist_libdocklet_desktop_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libdocklet_desktop_la_VALASOURCES) \
	desktop.gresource.xml \
	icons/show-desktop.svg \
	icons/window-cascade.svg \
	icons/window-tile.svg \
	$(NULL)

