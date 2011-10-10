include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

if USE_GTK3
SUFFIX=3
plank_VALAFLAGS = \
	$(PLANK_CORE_3_VALAFLAGS)
else
SUFFIX=
plank_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS)
endif

plank_VALAFLAGS += \
	$(top_srcdir)/lib/plank$(SUFFIX).vapi \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

plankdir = $(bindir)

BUILT_SOURCES = plank_vala.stamp

plank_PROGRAMS = plank

plank_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-I$(top_srcdir)/lib \
	$(NULL)
	
plank_LDADD = \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank$(SUFFIX).la \
	$(NULL)

plank_VALASOURCES = \
	PlankMain.vala \
	$(NULL)

plank_SOURCES = \
	plank_vala.stamp \
	$(plank_VALASOURCES:.vala=.c) \
	$(NULL)

plank_vala.stamp: $(plank_VALASOURCES)
	$(AM_V_VALA)$(VALAC) $(plank_VALAFLAGS) -C $(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

DISTCLEANFILES = \
	$(plank_SOURCES) \
	plank_vala.stamp \
	$(NULL)

EXTRA_DIST = \
	$(plank_VALASOURCES) \
	$(NULL)

