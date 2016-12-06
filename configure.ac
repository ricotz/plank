# If not 1, append revision to the version number and enable other development stuff
m4_define([plank_released], [1])

m4_define([plank_major_version], [0])
m4_define([plank_minor_version], [11])
m4_define([plank_micro_version], [3])
m4_define([plank_nano_version], [0])

# If library source has changed since last release, increment revision
# If interfaces have been added, removed or changed since last release,
#  increment current and set revision to 0
# If interfaces have been added since last release, increment age
# If interfaces have been removed since last release, set age to 0
m4_define([plank_lt_current], [1])
m4_define([plank_lt_revision], [0])
m4_define([plank_lt_age], [0])

# Display the nano_version only if it's not '0'
m4_define([plank_base_version],
          plank_major_version.plank_minor_version.plank_micro_version)
m4_define([plank_full_version],
          [m4_if(plank_nano_version, [0],
                 plank_base_version, plank_base_version.plank_nano_version)])

# Extend version with bzr revision for non-release builds
m4_define([plank_version], m4_if(plank_released, [1],
          [plank_full_version], [m4_esyscmd([build-aux/bzr-version-gen plank_full_version])]))
m4_define([plank_major_minor_version], plank_major_version.plank_minor_version)
m4_define([plank_module_version], plank_lt_current)

AC_INIT([plank], plank_version,
        [https://bugs.launchpad.net/plank], [plank],
        [https://launchpad.net/plank])
AC_DEFINE(RELEASE_NAME, "Stupidly simple.", Codename of this release)
AC_DEFINE(VERSION_INFO, m4_if(plank_released, [1], "Release", "Development"), Version info for package)
AC_DEFINE(VERSION_MAJOR, [plank_major_version], Major version of this package)
AC_DEFINE(VERSION_MINOR, [plank_minor_version], Minor version of this package)
AC_DEFINE(VERSION_MICRO, [plank_micro_version], Micro version of this package)
AC_DEFINE(VERSION_NANO, [plank_nano_version], Nano version of this package)

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_SRCDIR([configure.ac])
AM_INIT_AUTOMAKE([1.11 tar-ustar dist-xz no-dist-gzip -Wno-portability subdir-objects])

AM_MAINTAINER_MODE([enable])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CXX
AC_PROG_CXX_C_O
AC_PROG_INSTALL

LT_PREREQ([2.2.6])
LT_INIT([disable-static])
PKG_PROG_PKG_CONFIG([0.21])

LT_LIB_M

GLIB_GSETTINGS

AC_SUBST([CFLAGS])
AC_SUBST([CPPFLAGS])
AC_SUBST([LDFLAGS])

LT_CURRENT=plank_lt_current
LT_REVISION=plank_lt_revision
LT_AGE=plank_lt_age
AC_SUBST([LT_CURRENT])
AC_SUBST([LT_REVISION])
AC_SUBST([LT_AGE])

PLANK_MAJOR_MINOR_VERSION=plank_major_minor_version
AC_SUBST([PLANK_MAJOR_MINOR_VERSION])
PLANK_MAJOR_VERSION=plank_major_version
AC_SUBST([PLANK_MAJOR_VERSION])
PLANK_MINOR_VERSION=plank_minor_version
AC_SUBST([PLANK_MINOR_VERSION])
PLANK_MICRO_VERSION=plank_micro_version
AC_SUBST([PLANK_MICRO_VERSION])
PLANK_NANO_VERSION=plank_nano_version
AC_SUBST([PLANK_NANO_VERSION])

API_VERSION=0.11
AC_SUBST([API_VERSION])


# -----------------------------------------------------------
# Vala
# -----------------------------------------------------------
VALA_MIN_VERSION=0.26.0

AM_PROG_VALAC([$VALA_MIN_VERSION],
    [],
    [AC_MSG_ERROR([valac >= $VALA_MIN_VERSION is required])])

AC_PATH_PROG([VAPIGEN], [vapigen], [])
if test "x$VAPIGEN" = "x"; then
    AC_MSG_ERROR([Vala must be built with --enable-vapigen])
fi

# -----------------------------------------------------------
# Dependencies
# -----------------------------------------------------------
GTK_MIN_VERSION=3.10.0
GLIB_MIN_VERSION=2.40.0
GDK_PIXBUF_MIN_VERSION=2.26.0
BAMF_MIN_VERSION=0.2.92
CAIRO_MIN_VERSION=1.10

PLANK_CORE_PKGS="gobject-2.0 >= $GLIB_MIN_VERSION \
                 glib-2.0 >= $GLIB_MIN_VERSION \
                 gio-2.0 >= $GLIB_MIN_VERSION \
                 gio-unix-2.0 >= $GLIB_MIN_VERSION \
                 gmodule-2.0 \
                 gtk+-3.0 >= $GTK_MIN_VERSION \
                 gdk-x11-3.0 >= $GTK_MIN_VERSION \
                 gdk-pixbuf-2.0 >= $GDK_PIXBUF_MIN_VERSION \
                 cairo >= $CAIRO_MIN_VERSION \
                 gee-0.8 \
                 libbamf3 >= $BAMF_MIN_VERSION \
                 libwnck-3.0 \
                 x11"
PLANK_CORE_OPTIONAL_PKGS=""

PLANK_CORE_VALA_PKGS="--pkg gio-unix-2.0 \
                      --pkg gmodule-2.0 \
                      --pkg gtk+-3.0 \
                      --pkg gdk-x11-3.0 \
                      --pkg gdk-pixbuf-2.0 \
                      --pkg cairo \
                      --pkg gee-0.8 \
                      --pkg libbamf3 \
                      --pkg libwnck-3.0 \
                      --pkg posix \
                      --pkg x11"

VALAFLAGS_CORE=""

# Docklets
DOCKLET_LDFLAGS="-module -avoid-version"
AC_SUBST([DOCKLET_LDFLAGS])

# -----------------------------------------------------------
# GLib Resources
# -----------------------------------------------------------

AC_ARG_VAR([GLIB_COMPILE_RESOURCES],[the glib-compile-resources program])
AC_PATH_PROG([GLIB_COMPILE_RESOURCES],[glib-compile-resources],[])
if test -z "$GLIB_COMPILE_RESOURCES"; then
  AC_MSG_ERROR([glib-compile-resources not found])
fi

AC_ARG_VAR([XMLLINT],[the xmllint program])
AC_PATH_PROG([XMLLINT],[xmllint],[])
if test -z "$XMLLINT"; then
  AC_MSG_ERROR([xmllint not found])
fi


# -----------------------------------------------------------
# Dermine avaiable GLib version and adjust vala's
#   target-glib flag accoringly
# -----------------------------------------------------------

VALAFLAGS="--target-glib=2.40"

# -----------------------------------------------------------
# Optional Dependencies
# -----------------------------------------------------------

# Check for HiDPI support of Cairo
HIDPI_PKGS="cairo >= 1.13"
PKG_CHECK_MODULES(HIDPI, $HIDPI_PKGS, [enable_hidpi=yes], [enable_hidpi=no])
if test "x$enable_hidpi" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAVE_HIDPI"
fi
AM_CONDITIONAL([HAVE_HIDPI], [test "x$enable_hidpi" = "xyes"])

# Check for newer BAMF
BAMF_PKGS="libbamf3 >= 0.4.0"
PKG_CHECK_MODULES(BAMF, $BAMF_PKGS, [enable_bamf_0_4=yes], [enable_bamf_0_4=no])
if test "x$enable_bamf_0_4" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAVE_BAMF_0_4"
fi
AM_CONDITIONAL([HAVE_BAMF_0_4], [test "x$enable_bamf_0_4" = "xyes"])

# Support barrier-supported unhiding using Xinput 2.3
XFIXES_MIN_VERSION=5.0
XINPUT_MIN_VERSION=1.6.99.1
XINPUT_PKGS="xi >= $XINPUT_MIN_VERSION xfixes >= $XFIXES_MIN_VERSION"
AC_ARG_ENABLE([barriers],
              AS_HELP_STRING([--enable-barriers],
                             [Enable use of barriers]),
              [enable_barriers=$enableval],
              [enable_barriers=yes])
AC_CHECK_LIB([Xi], [XIBarrierReleasePointer], [enable_xinput23=yes], [enable_xinput23=no])
AC_CHECK_LIB([Xfixes], [XFixesDestroyPointerBarrier], [enable_xfixes50=yes], [enable_xfixes50=no])
if test "x$enable_barriers" = "xyes" -a "x$enable_xinput23" = "xyes" -a "x$enable_xfixes50" = "xyes" ; then
    PLANK_CORE_OPTIONAL_PKGS="$PLANK_CORE_OPTIONAL_PKGS $XINPUT_PKGS"
    PLANK_CORE_VALA_PKGS="$PLANK_CORE_VALA_PKGS --pkg xi --pkg xfixes"
    VALAFLAGS="$VALAFLAGS --define HAVE_BARRIERS"
else
	enable_barriers=no
fi
AM_CONDITIONAL([HAVE_BARRIERS], [test "x$enable_barriers" = "xyes" -a "x$enable_xinput23" = "xyes" -a "x$enable_xfixes50" = "xyes"])

# Support dynamic quicklists provided with dbusmenu
DBUSMENU_MIN_VERSION=0.4
DBUSMENU_PKGS="dbusmenu-glib-0.4 >= $DBUSMENU_MIN_VERSION dbusmenu-gtk3-0.4 >= $DBUSMENU_MIN_VERSION"
AC_ARG_ENABLE([dbusmenu],
              AS_HELP_STRING([--enable-dbusmenu],
                             [Enable dynamic quicklist support provided over dbusmenu]),
              [enable_dbusmenu=$enableval],
              [PKG_CHECK_MODULES(DBUSMENU, $DBUSMENU_PKGS, [enable_dbusmenu=yes], [enable_dbusmenu=no])])
if test "x$enable_dbusmenu" = "xyes" ; then
    PLANK_CORE_OPTIONAL_PKGS="$PLANK_CORE_OPTIONAL_PKGS $DBUSMENU_PKGS"
    PLANK_CORE_VALA_PKGS="$PLANK_CORE_VALA_PKGS --pkg Dbusmenu-0.4 --pkg DbusmenuGtk3-0.4"
    VALAFLAGS="$VALAFLAGS --define HAVE_DBUSMENU"
fi
AM_CONDITIONAL([HAVE_DBUSMENU], [test "x$enable_dbusmenu" = "xyes"])



AC_SUBST(PLANK_CORE_OPTIONAL_PKGS)
PLANK_CORE_PKGS="$PLANK_CORE_PKGS $PLANK_CORE_OPTIONAL_PKGS"
PKG_CHECK_MODULES(PLANK_CORE, $PLANK_CORE_PKGS)


# -----------------------------------------------------------
# Addional configure flags
# -----------------------------------------------------------

# Enable Vala debug-flag by default for non-release builds
AC_ARG_ENABLE([debug],
              AS_HELP_STRING([--disable-debug],[compile without debug code]),
              [enable_debug=$enableval], [m4_if(plank_released, [1], [enable_debug=no], [enable_debug=yes])])
if test "x$enable_debug" = "xyes" ; then
    VALAFLAGS_CORE="$VALAFLAGS_CORE -g"
fi

# Enable installation of Apport support files
AC_ARG_ENABLE([apport],
              AS_HELP_STRING([--enable-apport],[Enable installation of Apport support files]),
              [enable_apport=$enableval], [enable_apport=yes])
AM_CONDITIONAL([ENABLE_APPORT], [test "x$enable_apport" = "xyes"])

# Enable output of benchmarking data
AC_ARG_ENABLE([benchmark],
              AS_HELP_STRING([--enable-benchmark],
                             [Enable output of benchmarking data in logs]),
              [enable_benchmark=$enableval],
              [enable_benchmark=no])
if test "x$enable_benchmark" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define BENCHMARK"
fi

# Run checks and add build-flags to e.g. differenciate between Linux and BSD
AC_CHECK_HEADERS([sys/prctl.h], [VALAFLAGS="$VALAFLAGS --define HAVE_SYS_PRCTL_H"])

# Check to enable coverage
AC_TDD_GCOV
AM_CONDITIONAL([HAVE_GCOV], [test "x$ac_cv_check_gcov" = "xyes"])
AM_CONDITIONAL([HAVE_LCOV], [test "x$ac_cv_check_lcov" = "xyes"])
AM_CONDITIONAL([HAVE_GCOVR], [test "x$ac_cv_check_gcovr" = "xyes"])
if test "x$ac_cv_check_gcov" = "xyes" ; then
    COVERAGE_VALAFLAGS="-g"
fi
AC_SUBST(COVERAGE_VALAFLAGS)
AC_SUBST(COVERAGE_CFLAGS)
AC_SUBST(COVERAGE_LDFLAGS)

# Check to enable gmock and gtest
AC_GMOCK


PLANK_CORE_VALAFLAGS="$VALAFLAGS_CORE $VALAFLAGS $PLANK_CORE_VALA_PKGS"
AC_SUBST(PLANK_CORE_VALAFLAGS)
PLANK_DOCS_VALAFLAGS="$VALAFLAGS $PLANK_CORE_VALA_PKGS"
AC_SUBST(PLANK_DOCS_VALAFLAGS)


# -----------------------------------------------------------
# Additional build flags
# -----------------------------------------------------------

# Use RUNPATH instead of RPATH if needed
CFLAGS="$CFLAGS -Wl,--enable-new-dtags"

# -----------------------------------------------------------
# Documentation
# -----------------------------------------------------------
VALADOC_MIN_VERSION=0.3.1

AC_ARG_ENABLE([docs],
              AS_HELP_STRING([--enable-docs],[Enable documentation generation]),
              [enable_docs=$enableval], [enable_docs=no])
AM_CONDITIONAL([ENABLE_DOCS], [test "x$enable_docs" = "xyes"])

have_valadoc=no
if test "x$enable_docs" = "xyes"; then
    # make sure the library is new enough and the program exists
    PKG_CHECK_MODULES([VALADOC], [valadoc-1.0 >= $VALADOC_MIN_VERSION])
    AC_PATH_PROG([VALADOC], [valadoc], [:])
    AS_IF([test "$VALADOC" != :], have_valadoc=yes)
fi
AM_CONDITIONAL([HAVE_VALADOC], [test "x$have_valadoc" = "xyes"])

if test "x$enable_docs" = "xyes" -a "x$have_valadoc" != "xyes"; then
    AC_MSG_ERROR([Doc building requested but valadoc not installed.])
fi


# -----------------------------------------------------------
# Test Dependencies
# -----------------------------------------------------------
AC_ARG_ENABLE([headless-tests],
              AS_HELP_STRING([--enable-headless-tests], [Enable running tests in headless mode]),
              [enable_headless_tests=$enableval], [enable_headless_tests=no])
if test "x$enable_headless_tests" != "xno"; then
    AC_PATH_PROG([XVFB_RUN], [xvfb-run], [:])
    AC_PATH_PROG([DBUS_LAUNCH], [dbus-launch], [:])
    AS_IF([test "$XVFB_RUN" != :], [have_xvfb_run=yes], [have_xvfb_run=no])
    AS_IF([test "$DBUS_LAUNCH" != :], [have_dbus_launch=yes], [have_dbus_launch=no])
fi
AM_CONDITIONAL(HAVE_HEADLESS_TESTS, [test "x$have_xvfb_run" == "xyes" -a "x$have_dbus_launch" == "xyes"])

if test "x$enable_headless_tests" = "xyes"; then
  if test "x$have_xvfb_run" != "xyes" -o "x$have_dbus_launch" != "xyes"; then
    AC_MSG_ERROR([Headless Tests requested but xvfb-run/dbus-launch not installed.])
  fi
fi


# -----------------------------------------------------------
# Gettext
# -----------------------------------------------------------
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, ["$GETTEXT_PACKAGE"], [Define the gettext package to be used])
IT_PROG_INTLTOOL([0.35.0])


# -----------------------------------------------------------
# Final output
# -----------------------------------------------------------
AC_CONFIG_FILES([
Makefile
data/Makefile
data/net.launchpad.plank.gschema.xml.in
data/apport/Makefile
data/icons/Makefile
data/themes/Makefile
lib/Makefile
lib/plank.pc
lib/Version.vala
src/Makefile
docklets/Makefile
docklets/Clippy/Makefile
docklets/Clock/Makefile
docklets/CPUMonitor/Makefile
docklets/Desktop/Makefile
docklets/Trash/Makefile
docs/Makefile
po/Makefile.in
tests/Makefile
examples/Makefile
vapi/Makefile
])

AC_OUTPUT

echo "
${PACKAGE} ${VERSION}

    Prefix......................:  ${prefix}
    Vala Compiler...............:  ${VALAC}
    Vala Flags..................:  ${VALAFLAGS}
    C Compiler Flags............:  ${CFLAGS}

    Dbusmenu support............:  ${enable_dbusmenu}
    HiDPI support...............:  ${enable_hidpi}
    XInput Barriers support.....:  ${enable_barriers}

    Apport support..............:  ${enable_apport}

    Headless Tests..............:  ${enable_headless_tests}
    Google-Mock Tests...........:  ${use_gmock}
    Coverage Reporting..........:  ${use_gcov}
    Documentation...............:  ${have_valadoc}
"
