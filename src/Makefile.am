include $(top_srcdir)/Makefile.common

plank_VALAFLAGS = \
	$(COVERAGE_VALAFLAGS) \
	$(PLANK_CORE_VALAFLAGS) \
	$(top_builddir)/lib/plank.vapi \
	--vapidir $(top_srcdir)/vapi \
	$(top_srcdir)/vapi/config.vapi \
	-C \
	$(NULL)

BUILT_SOURCES = plank_vala.stamp

bin_PROGRAMS = plank

plank_CFLAGS = \
	$(COVERAGE_CFLAGS) \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-w \
	-I$(top_builddir)/lib \
	$(NULL)

plank_LDADD = \
	$(COVERAGE_LDFLAGS) \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

plank_LDFLAGS = \
	-L$(pkglibdir) \
	$(NULL)

plank_VALASOURCES = \
	Main.vala \
	$(NULL)

nodist_plank_SOURCES = \
	$(plank_VALASOURCES:.vala=.c) \
	$(NULL)

$(plank_VALASOURCES:.vala=.c): plank_vala.stamp

plank_vala.stamp: $(plank_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(plank_VALAFLAGS) \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	plank_vala.stamp \
	$(nodist_plank_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(plank_VALASOURCES) \
	$(NULL)

