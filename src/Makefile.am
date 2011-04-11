VAPIDIR = $(top_srcdir)/vapi

VALAFLAGS = \
	--thread \
	$(PLANK_CORE_VALA_PKGS) \
	$(top_builddir)/lib/plank.vapi \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

plankdir = $(bindir)

plank_PROGRAMS = \
	plank \
	$(NULL)

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

plank_SOURCES = $(plank_VALASOURCES:.vala=.c)

$(plank_SOURCES): plank_vala.stamp

plank_vala.stamp: $(plank_VALASOURCES) Makefile
	$(AM_V_VALA)$(VALAC) $(plank_VALAFLAGS) $(VALAFLAGS) -C $(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

DISTCLEANFILES = \
	$(plank_SOURCES) \
	plank_vala.stamp \
	$(NULL)

EXTRA_DIST = \
	$(plank_VALASOURCES) \
	$(NULL)

#dist-hook:
#	rm -rf $(addprefix $(distdir)/, $(plank_SOURCES) plank_vala.stamp)
