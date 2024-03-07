include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

BUILT_SOURCES = \
	$(NULL)

libdocklet_battery_la_LTLIBRARIES = libdocklet-battery.la

libdocklet_battery_ladir = $(pkglibdir)/docklets

libdocklet_battery_la_VALASOURCES = \
	BatteryUPowerDockItem.vala \
	BatteryDockItem.vala \
	BatteryDocklet.vala \
	$(NULL)

nodist_libdocklet_battery_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libdocklet_battery_la_VALASOURCES:.vala=.c) \
	$(NULL)

libdocklet_battery_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(VAPIDIR)/config.vapi \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_builddir)/lib \
	--pkg plank \
	$(NULL)

libdocklet_battery_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libdocklet_battery_la_LDFLAGS = \
	$(DOCKLET_LDFLAGS) \
	$(PLANK_CORE_LDFLAGS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

libdocklet_battery_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-I$(top_builddir)/lib \
	$(NULL)

$(libdocklet_battery_la_VALASOURCES:.vala=.c): libdocklet_battery_la_vala.stamp

libdocklet_battery_la_vala.stamp: $(libdocklet_battery_la_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libdocklet_battery_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	libdocklet_battery_la_vala.stamp \
	$(nodist_libdocklet_battery_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libdocklet_battery_la_VALASOURCES) \
	$(NULL)
