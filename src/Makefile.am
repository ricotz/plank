VAPIDIR = $(top_srcdir)/vapi

VALAFLAGS = \
	--thread \
	$(PLANK_CORE_VALA_PKGS) \
	--vapidir $(VAPIDIR) \
	../lib/plank.vapi \
	$(VAPIDIR)/config.vapi \
	$(NULL)

plankdir = $(bindir)

plank_PROGRAMS = \
	plank \
	$(NULL)

plank_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-I ../lib \
	$(NULL)
	
plank_LDADD = \
	$(PLANK_CORE_LIBS) \
	../lib/libplank.la \
	$(NULL)

plank_VALASOURCES = \
	PlankMain.vala \
	$(NULL)

GENERATED_C_FILES = $(plank_VALASOURCES:.vala=.c)
plank_SOURCES = $(plank_VALASOURCES:.vala=.c)

$(GENERATED_C_FILES): plank_vala.stamp

plank_vala.stamp: $(addprefix $(srcdir)/,$(plank_VALASOURCES))
	$(AM_V_VALA)$(VALAC) $(plank_VALAFLAGS) $(VALAFLAGS) -C $^
	$(AM_V_at)touch $@

CLEANFILES = $(GENERATED_C_FILES) plank_vala.stamp
EXTRA_DIST = $(plank_VALASOURCES)

# need to make sure the vala sources are rebuilt
dist-hook:
	rm -rf $(addprefix $(distdir)/,$(GENERATED_C_FILES) plank_vala.stamp)
