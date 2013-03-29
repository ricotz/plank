include $(top_srcdir)/Makefile.common

tests_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(top_builddir)/lib/plank.vapi \
	$(top_builddir)/lib/plank-internal.vapi \
	--vapidir $(top_srcdir)/vapi \
	$(top_srcdir)/vapi/config.vapi \
	$(srcdir)/test-config.vapi \
	-C \
	$(NULL)

BUILT_SOURCES = tests_vala.stamp

check_PROGRAMS = tests

tests_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-DTEST_DATA_DIR=\"$(abs_top_srcdir)/data\" \
	-DTEST_HOME_DIR=\"$(abs_builddir)\" \
	-I$(top_builddir)/lib \
	-I$(top_srcdir) \
	$(NULL)

tests_LDADD = \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank.la \
	$(top_builddir)/lib/libplank-internal.la \
	$(NULL)

tests_VALASOURCES = \
	Drawing.vala \
	Items.vala \
	Main.vala \
	$(NULL)

nodist_tests_SOURCES = \
	tests_vala.stamp \
	$(tests_VALASOURCES:.vala=.c) \
	$(NULL)

tests_vala.stamp: $(tests_VALASOURCES)
	$(AM_V_VALA)$(VALAC) \
		$(tests_VALAFLAGS) \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	$(nodist_tests_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(tests_VALASOURCES) \
	test-config.h \
	test-config.vapi \
	$(NULL)

check-local:
	gtester --verbose $(builddir)/tests

