include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

BUILT_SOURCES = \
	docky-clock-resources.c \
	$(NULL)

libdocklet_clock_la_LTLIBRARIES = libdocklet-clock.la

libdocklet_clock_ladir = $(pkglibdir)/docklets

libdocklet_clock_la_VALASOURCES = \
	ClockDockItem.vala \
	ClockDocklet.vala \
	ClockPreferences.vala \
	$(NULL)

nodist_libdocklet_clock_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libdocklet_clock_la_VALASOURCES:.vala=.c) \
	$(NULL)

libdocklet_clock_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(VAPIDIR)/config.vapi \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_builddir)/lib \
	--pkg plank \
	$(NULL)

libdocklet_clock_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libdocklet_clock_la_LDFLAGS = \
	$(DOCKLET_LDFLAGS) \
	$(PLANK_CORE_LDFLAGS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

libdocklet_clock_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h -w \
	-I$(top_builddir)/lib \
	$(NULL)

docky-clock-resources.c: $(srcdir)/clock.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(srcdir) $(srcdir)/clock.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(srcdir) --generate --c-name docky_clock $<

$(libdocklet_clock_la_VALASOURCES:.vala=.c): libdocklet_clock_la_vala.stamp

libdocklet_clock_la_vala.stamp: $(libdocklet_clock_la_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libdocklet_clock_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	libdocklet_clock_la_vala.stamp \
	$(nodist_libdocklet_clock_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libdocklet_clock_la_VALASOURCES) \
	clock.gresource.xml \
	themes/Default/clock-drop-shadow.svg \
	themes/Default/clock-face.svg \
	themes/Default/clock-face-shadow.svg \
	themes/Default/clock-frame.svg \
	themes/Default/clock-glass.svg \
	themes/Default/clock-marks.svg \
	themes/Default24/clock-drop-shadow.svg \
	themes/Default24/clock-face.svg \
	themes/Default24/clock-face-shadow.svg \
	themes/Default24/clock-frame.svg \
	themes/Default24/clock-glass.svg \
	themes/Default24/clock-marks.svg \
	$(NULL)

