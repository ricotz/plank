include $(top_srcdir)/Makefile.common

remote_client_VALAFLAGS = \
	$(COVERAGE_VALAFLAGS) \
	$(PLANK_CORE_VALAFLAGS) \
	$(top_builddir)/lib/plank.vapi \
	--vapidir $(top_srcdir)/vapi \
	-C \
	$(NULL)

noinst_PROGRAMS = remote-client

remote_client_CFLAGS = \
	$(COVERAGE_CFLAGS) \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-w \
	-I$(top_builddir)/lib \
	$(NULL)

remote_client_LDADD = \
	$(COVERAGE_LDFLAGS) \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

remote_client_VALASOURCES = \
	RemoteClient.vala \
	$(NULL)

nodist_remote_client_SOURCES = \
	$(remote_client_VALASOURCES:.vala=.c) \
	$(NULL)

$(remote_client_VALASOURCES:.vala=.c): remote_client_vala.stamp

remote_client_vala.stamp: $(remote_client_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(remote_client_VALAFLAGS) \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	remote_client_vala.stamp \
	$(nodist_remote_client_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(remote_client_VALASOURCES) \
	$(NULL)

