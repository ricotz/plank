# If not 1, append revision to the version number and enable other development stuff
m4_define([plank_released], [0])

m4_define([plank_major_version], [0])
m4_define([plank_minor_version], [2])
m4_define([plank_micro_version], [0])
m4_define([plank_nano_version], [0])

# If library source has changed since last release, increment revision
# If interfaces have been added, removed or changed since last release,
#  increment current and set revision to 0
# If interfaces have been added since last release, increment age
# If interfaces have been removed since last release, set age to 0
m4_define([plank_lt_current], [0])
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

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_SRCDIR([configure.ac])
AM_INIT_AUTOMAKE([1.11 tar-ustar dist-xz no-dist-gzip -Wno-portability])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
LT_INIT
PKG_PROG_PKG_CONFIG([0.21])

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

API_VERSION=0.2
AC_SUBST([API_VERSION])

# -----------------------------------------------------------
# Dependencies
# -----------------------------------------------------------
GTK_MIN_VERSION=2.22.0
GLIB_MIN_VERSION=2.26.0
VALA_MIN_VERSION=0.10.0
VALADOC_MIN_VERSION=0.3.1
BAMF_MIN_VERSION=0.2.58

PKG_CHECK_MODULES(PLANK_CORE, gobject-2.0 >= $GLIB_MIN_VERSION
                              glib-2.0 >= $GLIB_MIN_VERSION
                              gthread-2.0 >= $GLIB_MIN_VERSION
                              gio-2.0 >= $GLIB_MIN_VERSION
                              gio-unix-2.0 >= $GLIB_MIN_VERSION
                              gtk+-2.0 >= $GTK_MIN_VERSION
                              gdk-x11-2.0 >= $GTK_MIN_VERSION
                              libbamf >= $BAMF_MIN_VERSION
                              gee-1.0
                              libwnck-1.0
                              unique-1.0
                              x11
)

#
# Vala building options -- allows tarball builds without installing Vala
#
AC_ARG_ENABLE([vala],
              AS_HELP_STRING([--enable-vala],
                             [Enable building from the Vala sources]),
              [enable_vala=$enableval],
              [enable_vala=no])

# Force Vala for non-release builds
m4_if(plank_released, [1], [],
    [
        enable_vala=yes
        echo "Vala compiler required for non-release builds; requiring Vala..."
    ])

# Enable Vala debug-flag by default for non-release builds
AC_ARG_ENABLE([debug],
              AS_HELP_STRING([--disable-debug],[compile without debug code]),
              [enable_debug=$enableval], [m4_if(plank_released, [1], [enable_debug=no], [enable_debug=yes])])
if test "x$enable_debug" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS -g"
fi

# Force Vala if generated source is missing or outdated
if test \
    ! -e ${srcdir}/lib/libplank_la_vala.stamp -o \
    ! -e ${srcdir}/src/plank_vala.stamp ; then
    enable_vala=yes
    echo "Vala source needs to be re-compiled; requiring Vala..."
fi

if test "x$enable_vala" = "xyes" ; then
    AM_PROG_VALAC([$VALA_MIN_VERSION])
    if test "x$VALAC" = "x"; then
        AC_MSG_ERROR([Vala requested but valac >= $VALA_MIN_VERSION is not installed])
    fi

    AC_PATH_PROG([VAPIGEN], [vapigen], [])
    if test "x$VAPIGEN" = "x"; then
        AC_MSG_ERROR([Vala must be built with --enable-vapigen])
    fi

    PLANK_CORE_VALA_PKGS="--pkg gdk-x11-2.0 \
                          --pkg gtk+-2.0 \
                          --pkg gio-unix-2.0 \
                          --pkg bamf \
                          --pkg gee-1.0 \
                          --pkg libwnck-1.0 \
                          --pkg posix \
                          --pkg unique-1.0 \
                          --pkg x11"
    AC_SUBST(PLANK_CORE_VALA_PKGS)

    VALAFLAGS="$VALAFLAGS --thread --target-glib=2.26"
    AC_SUBST(VALAFLAGS)

    PLANK_CORE_VALAFLAGS="$VALAFLAGS $PLANK_CORE_VALA_PKGS"
    AC_SUBST(PLANK_CORE_VALAFLAGS)
fi


# -----------------------------------------------------------
# Documentation
# -----------------------------------------------------------
AC_ARG_ENABLE([docs],
              AS_HELP_STRING([--enable-docs],[Enable documentation generation]),
              [enable_docs=$enableval], [enable_docs=no])
AM_CONDITIONAL([ENABLE_DOCS], [test x$enable_docs = xyes])

have_valadoc=no
if test x$enable_docs = xyes; then
    # make sure the library is new enough and the program exists
    PKG_CHECK_MODULES([VALADOC], [valadoc-1.0 >= $VALADOC_MIN_VERSION])
    AC_PATH_PROG([VALADOC], [valadoc], [:])
    AS_IF([test "$VALADOC" != :], have_valadoc=yes)
fi
AM_CONDITIONAL([HAVE_VALADOC], [test x$have_valadoc = xyes])

if test "x$enable_docs" = "xyes" -a "x$have_valadoc" != "xyes"; then
    AC_MSG_ERROR([Doc building requested but valadoc not installed.])
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
data/icons/Makefile
data/icons/hicolor/Makefile
data/icons/hicolor/16x16/Makefile
data/icons/hicolor/16x16/apps/Makefile
data/icons/hicolor/22x22/Makefile
data/icons/hicolor/22x22/apps/Makefile
data/icons/hicolor/24x24/Makefile
data/icons/hicolor/24x24/apps/Makefile
data/icons/hicolor/32x32/Makefile
data/icons/hicolor/32x32/apps/Makefile
data/icons/hicolor/48x48/Makefile
data/icons/hicolor/48x48/apps/Makefile
data/icons/hicolor/64x64/Makefile
data/icons/hicolor/64x64/apps/Makefile
data/icons/hicolor/128x128/Makefile
data/icons/hicolor/128x128/apps/Makefile
data/themes/Makefile
data/themes/Default/Makefile
data/themes/Matte/Makefile
data/themes/Transparent/Makefile
lib/Makefile
lib/libplank.pc
m4/Makefile
man/Makefile
src/Makefile
docs/Makefile
po/Makefile.in
vapi/Makefile
])

AC_OUTPUT

echo "
${PACKAGE} ${VERSION}

    Prefix......................:  ${prefix}
    Vala........................:  ${enable_vala}
    Vala Compiler...............:  ${VALAC}
    Vala Flags..................:  ${VALAFLAGS}
    C Compiler Flags............:  ${CFLAGS}
    Documentation...............:  ${have_valadoc}
"
