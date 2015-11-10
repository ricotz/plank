include $(top_srcdir)/Makefile.common

AM_VALAFLAGS = \
	$(COVERAGE_VALAFLAGS) \
	$(PLANK_CORE_VALAFLAGS) \
	$(top_builddir)/lib/plank.vapi \
	$(top_builddir)/lib/plank-internal.vapi \
	--vapidir $(top_srcdir)/vapi \
	$(top_srcdir)/vapi/config.vapi \
	$(srcdir)/test-config.vapi \
	-C \
	$(NULL)

BUILT_SOURCES = tests_vala.stamp dock_vala.stamp

check_PROGRAMS = tests dock

tests_CFLAGS = \
	$(COVERAGE_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-DTEST_DATA_DIR=\"$(abs_srcdir)/data\" \
	-DTEST_HOME_DIR=\"$(abs_builddir)/home\" \
	-I$(top_builddir)/lib \
	-I$(top_srcdir) \
	$(NULL)

tests_LDADD = \
	$(COVERAGE_LDFLAGS) \
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
	TestHelper.vala \
	$(NULL)

nodist_tests_SOURCES = \
	$(tests_VALASOURCES:.vala=.c) \
	$(NULL)

$(tests_VALASOURCES:.vala=.c): tests_vala.stamp

tests_vala.stamp: $(tests_VALASOURCES) $(top_builddir)/lib/plank.vapi $(top_builddir)/lib/plank-internal.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(AM_VALAFLAGS) \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@


dock_CFLAGS = $(tests_CFLAGS)
dock_LDADD = $(tests_LDADD)

dock_VALASOURCES = \
	Dock.vala \
	$(NULL)

nodist_dock_SOURCES = \
	$(dock_VALASOURCES:.vala=.c) \
	$(NULL)

$(dock_VALASOURCES:.vala=.c): dock_vala.stamp

dock_vala.stamp: $(dock_VALASOURCES) $(top_builddir)/lib/plank.vapi $(top_builddir)/lib/plank-internal.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(AM_VALAFLAGS) \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	dock_vala.stamp \
	tests_vala.stamp \
	$(nodist_dock_SOURCES) \
	$(nodist_tests_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(dock_VALASOURCES) \
	$(tests_VALASOURCES) \
	test-config.h \
	test-config.vapi \
	data \
	$(NULL)

TESTS_ENVIRONMENT = HOME=$(abs_builddir)/home GSETTINGS_SCHEMA_DIR=$(abs_top_builddir)/data PLANK_DOCKLET_DIRS=$(abs_top_builddir)/docklets

if HAVE_HEADLESS_TESTS
TESTS_ENVIRONMENT += $(XVFB_RUN) --auto-servernum --server-args="-screen 0 1280x1024x24" $(DBUS_LAUNCH)
endif

check-local: clean-local
	$(TESTS_ENVIRONMENT) gtester --verbose --keep-going -o=$(builddir)/test-report.xml $(builddir)/tests
	$(TESTS_ENVIRONMENT) $(builddir)/dock -n test1

clean-local:
	rm -rf $(abs_builddir)/home $(builddir)/test-report.xml


if HAVE_GMOCK
include $(top_srcdir)/Makefile.gmock

noinst_PROGRAMS = gmock-tests
check_PROGRAMS += gmock-tests

gmock_tests_CXXFLAGS = \
	$(COVERAGE_CFLAGS) \
	$(GMOCK_CLFAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-I$(top_builddir)/lib \
	-I$(top_srcdir) \
	$(NULL)

gmock_tests_LDADD = \
	$(COVERAGE_LDFLAGS) \
	$(GMOCK_LDFLAGS) \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank.la \
	$(top_builddir)/lib/libplank-internal.la \
	$(NULL)

gmock_tests_SOURCES = \
	gmock/main.cpp \
	gmock/color.cpp \
	$(NULL)

endif
