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
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-DTEST_DATA_DIR=\"$(abs_srcdir)/data\" \
	-DTEST_HOME_DIR=\"$(abs_builddir)/home\" \
	-I$(top_builddir)/lib \
	-I$(top_srcdir) \
	$(NULL)

tests_LDADD = \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank.la \
	$(top_builddir)/lib/libplank-internal.la \
	$(NULL)

tests_VALASOURCES = \
	Controller.vala \
	Drawing.vala \
	Items.vala \
	Preferences.vala \
	Widgets.vala \
	Main.vala \
	$(NULL)

nodist_tests_SOURCES = \
	tests_vala.stamp \
	$(tests_VALASOURCES:.vala=.c) \
	$(NULL)

tests_vala.stamp: $(tests_VALASOURCES) $(top_builddir)/lib/plank.vapi $(top_builddir)/lib/plank-internal.vapi Makefile
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
	data \
	$(NULL)

TESTS_ENVIRONMENT = HOME=$(abs_builddir)/home

if HAVE_HEADLESS_TESTS
TESTS_ENVIRONMENT += $(XVFB_RUN) --server-args="-screen 0 1280x1024x24" $(DBUS_LAUNCH)
endif

check-local:
	rm -rf $(abs_builddir)/home $(builddir)/test-report.xml; \
	$(TESTS_ENVIRONMENT) gtester --verbose --keep-going -o=$(builddir)/test-report.xml $(builddir)/tests

clean-local:
	rm -rf $(abs_builddir)/home $(builddir)/test-report.xml
