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
	docs \
	$(NULL)

DISTCHECK_CONFIGURE_FLAGS = \
	--enable-barriers \
	--enable-dbusmenu \
	--enable-docs \
	--enable-headless-tests \
	$(NULL)

EXTRA_DIST = \
	autogen.sh \
	COPYING.LGPL2.1 \
	COPYRIGHT \
	HACKING \
	.version \
	build-aux/git-version-gen \
	build-aux/gitlog-to-changelog \
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
	@if test -d "$(srcdir)/.git"; then \
		($(srcdir)/build-aux/gitlog-to-changelog --format='%s%n%n%b%n' --no-cluster --strip-tab --strip-cherry-pick) | fmt --split-only --width=80 > $@.tmp \
		&& mv -f $@.tmp $@ \
		|| ($(RM) $@.tmp; \
			echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
			(test -f $@ || echo git is required to generate this file >> $@)); \
	else \
		test -f $@ || \
		(echo A git checkout and git is required to generate ChangeLog >&2 && \
		echo A git checkout and git is required to generate this file >> $@); \
	fi

.PHONY: ChangeLog

