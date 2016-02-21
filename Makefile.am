include $(top_srcdir)/Makefile.common
include $(top_srcdir)/Makefile.coverage

ACLOCAL_AMFLAGS = --install -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = \
	data \
	lib \
	docklets \
	po \
	vapi \
	src \
	tests \
	examples \
	$(NULL)

if HAVE_VALADOC
SUBDIRS += docs
endif

DISTCHECK_CONFIGURE_FLAGS = \
	--enable-barriers \
	--enable-dbusmenu \
	--enable-docs \
	--enable-gee-0.8 \
	--enable-headless-tests \
	$(NULL)

EXTRA_DIST = \
	autogen.sh \
	COPYING.LGPL2.1 \
	COPYRIGHT \
	HACKING \
	.version \
	build-aux/bzr-version-gen \
	$(NULL)

BUILT_SOURCES = \
	$(top_srcdir)/.version \
	$(NULL)

$(top_srcdir)/.version:
	echo $(VERSION) > $@-t && mv $@-t $@

dist-hook:
	echo $(VERSION) > $(distdir)/.tarball-version

distclean-local:
	if test "x$(srcdir)" = "x."; then :; else \
		rm -f ChangeLog; \
	fi

run: all
	GSETTINGS_SCHEMA_DIR=$(abs_top_builddir)/data PLANK_DOCKLET_DIRS=$(abs_top_builddir)/docklets \
		$(top_builddir)/src/plank -v

run-debug: all
	GSETTINGS_SCHEMA_DIR=$(abs_top_builddir)/data PLANK_DOCKLET_DIRS=$(abs_top_builddir)/docklets \
		libtool --mode=execute gdb --args $(top_builddir)/src/plank -v

ChangeLog:
	@echo Creating $@
	@if test -d "$(srcdir)/.bzr"; then \
		(bzr log --gnu -n1) | fmt --split-only --width=80 > $@.tmp \
		&& mv -f $@.tmp $@ \
		|| ($(RM) $@.tmp; \
			echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
			(test -f $@ || echo bzr is required to generate this file >> $@)); \
	else \
		test -f $@ || \
		(echo A bzr checkout and bzr is required to generate ChangeLog >&2 && \
		echo A bzr checkout and bzr is required to generate this file >> $@); \
	fi

.PHONY: ChangeLog

