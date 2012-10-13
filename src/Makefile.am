include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

plank_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS)

plank_VALAFLAGS += \
	$(top_builddir)/lib/plank.vapi \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

plankdir = $(bindir)

BUILT_SOURCES = plank_vala.stamp

plank_PROGRAMS = plank

plank_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-I$(top_builddir)/lib \
	$(NULL)

plank_LDADD = \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

plank_VALASOURCES = \
	PlankMain.vala \
	$(NULL)

nodist_plank_SOURCES = \
	plank_vala.stamp \
	$(plank_VALASOURCES:.vala=.c) \
	$(NULL)

plank_vala.stamp: $(plank_VALASOURCES)
	$(AM_V_VALA)$(VALAC) \
		$(plank_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	$(nodist_plank_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(plank_VALASOURCES) \
	$(NULL)

