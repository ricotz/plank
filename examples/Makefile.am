include $(top_srcdir)/Makefile.common

AM_VALAFLAGS = \
	$(COVERAGE_VALAFLAGS) \
	$(PLANK_CORE_VALAFLAGS) \
	$(top_builddir)/lib/plank.vapi \
	--vapidir $(top_srcdir)/vapi \
	-C \
	$(NULL)

AM_CFLAGS = \
	$(COVERAGE_CFLAGS) \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-w \
	-I$(top_builddir)/lib \
	$(NULL)

noinst_PROGRAMS = \
	remote-client \
	unity-client \
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
		$(AM_VALAFLAGS) \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

unity_client_LDADD = \
	$(COVERAGE_LDFLAGS) \
	$(PLANK_CORE_LIBS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

unity_client_VALASOURCES = \
	UnityClient.vala \
	$(NULL)

nodist_unity_client_SOURCES = \
	$(unity_client_VALASOURCES:.vala=.c) \
	$(NULL)

$(unity_client_VALASOURCES:.vala=.c): unity_client_vala.stamp

unity_client_vala.stamp: $(unity_client_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(AM_VALAFLAGS) \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	remote_client_vala.stamp \
	unity_client_vala.stamp \
	$(nodist_remote_client_SOURCES) \
	$(nodist_unity_client_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(remote_client_VALASOURCES) \
	$(unity_client_VALASOURCES) \
	$(NULL)

