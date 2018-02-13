include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

libdocklet_applications_la_LTLIBRARIES = libdocklet-applications.la

libdocklet_applications_ladir = $(pkglibdir)/docklets

libdocklet_applications_la_VALASOURCES = \
	ApplicationsDockItem.vala \
	ApplicationsDocklet.vala \
	$(NULL)

nodist_libdocklet_applications_la_SOURCES = \
	$(libdocklet_applications_la_VALASOURCES:.vala=.c) \
	$(NULL)

libdocklet_applications_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(GNOMEMENU3_VALAFLAGS) \
	$(VAPIDIR)/config.vapi \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_builddir)/lib \
	--pkg plank \
	$(NULL)

libdocklet_applications_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(GNOMEMENU3_LIBS) \
	$(NULL)

libdocklet_applications_la_LDFLAGS = \
	$(DOCKLET_LDFLAGS) \
	$(PLANK_CORE_LDFLAGS) \
	$(GNOMEMENU3_LDFLAGS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

libdocklet_applications_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE \
	$(GNOMEMENU3_CFLAGS) \
	-include config.h -w \
	-I$(top_builddir)/lib \
	$(NULL)

$(libdocklet_applications_la_VALASOURCES:.vala=.c): libdocklet_applications_la_vala.stamp

libdocklet_applications_la_vala.stamp: $(libdocklet_applications_la_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libdocklet_applications_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	libdocklet_applications_la_vala.stamp \
	$(nodist_libdocklet_applications_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libdocklet_applications_la_VALASOURCES) \
	$(NULL)

