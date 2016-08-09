include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

libdocklet_cpumonitor_la_LTLIBRARIES = libdocklet-cpumonitor.la

libdocklet_cpumonitor_ladir = $(pkglibdir)/docklets

libdocklet_cpumonitor_la_VALASOURCES = \
	CPUMonitorDockItem.vala \
	CPUMonitorDocklet.vala \
	$(NULL)

nodist_libdocklet_cpumonitor_la_SOURCES = \
	$(libdocklet_cpumonitor_la_VALASOURCES:.vala=.c) \
	$(NULL)

libdocklet_cpumonitor_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(VAPIDIR)/config.vapi \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_builddir)/lib \
	--pkg plank \
	$(NULL)

libdocklet_cpumonitor_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libdocklet_cpumonitor_la_LDFLAGS = \
	$(DOCKLET_LDFLAGS) \
	$(PLANK_CORE_LDFLAGS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

libdocklet_cpumonitor_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h -w \
	-I$(top_builddir)/lib \
	$(NULL)

$(libdocklet_cpumonitor_la_VALASOURCES:.vala=.c): libdocklet_cpumonitor_la_vala.stamp

libdocklet_cpumonitor_la_vala.stamp: $(libdocklet_cpumonitor_la_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libdocklet_cpumonitor_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	libdocklet_cpumonitor_la_vala.stamp \
	$(nodist_libdocklet_cpumonitor_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libdocklet_cpumonitor_la_VALASOURCES) \
	$(NULL)

