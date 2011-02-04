AC_INIT([plank], [0.1.0])
AC_DEFINE(RELEASE_NAME, "Stupidly simple", Codename of this release)

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([.])
AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.11 foreign tar-pax])

dnl -- Populate top_srcdir variable
top_srcdir=$(readlink -f $0 | sed -e s/configure$//)

dnl ==============================================
dnl Translation support
dnl ==============================================

GETTEXT_PACKAGE=plank
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [Gettext package])
ALL_LINGUAS=`ls ${top_srcdir}/po/*.po | sed 's/.po$//' | sed 's/.*\///' | tr '\n' ' '`

IT_PROG_INTLTOOL([0.35.0])
AM_GLIB_GNU_GETTEXT

dnl pkg-config
AC_PATH_PROG(PKG_CONFIG, pkg-config, no)
if test "x$PKG_CONFIG" = "xno"; then
        AC_MSG_ERROR([You need to install pkg-config])
fi

AC_PROG_INSTALL
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_LIBTOOL
AC_STDC_HEADERS

dnl ==============================================
dnl Set dependency versions
dnl ==============================================
AC_MSG_CHECKING([which GTK version to compile against])
AC_ARG_WITH([gtk],
   AC_HELP_STRING([--with-gtk=2.0|3.0],
   [which GTK version to compile against (default: 2.0)]),
   [case "$with_gtk" in
       2.0|3.0) ;;
       *) AC_MSG_ERROR([invalid GTK version specified]);;
   esac],
   [with_gtk=2.0])
AC_MSG_RESULT([$with_gtk])

case "$with_gtk" in
   2.0) GTK_API_VERSION=2.0
        GTK_MIN_VERSION=2.22.0
        GLIB_MIN_VERSION=2.26.0
        VALA_MIN_VERSION=0.10.0
   ;;
   3.0) GTK_API_VERSION=3.0
        GTK_MIN_VERSION=2.99.2
        GLIB_MIN_VERSION=2.27.91
        VALA_MIN_VERSION=0.11.5
   ;;
esac
AC_SUBST(GTK_API_VERSION)

dnl ==============================================
dnl Check that we meet the dependencies
dnl ==============================================
AM_PROG_VALAC([$VALA_MIN_VERSION])
if test "x$VALAC" = "x"; then
	AC_MSG_ERROR([You need a Vala $VALA_MIN_VERSION compiler])
fi

PKG_CHECK_MODULES(PLANK_CORE, gobject-2.0 >= $GLIB_MIN_VERSION
                              glib-2.0 >= $GLIB_MIN_VERSION
                              gio-2.0 >= $GLIB_MIN_VERSION
                              gtk+-$GTK_API_VERSION >= $GTK_MIN_VERSION
                              gee-1.0
                              unique-1.0
                              x11
                              libwnck-1.0
                              libbamf
)

dnl Expansions
AS_AC_EXPAND([PKGDATADIR], [$datadir/$PACKAGE_NAME])
AS_AC_EXPAND([DATADIR], [$datadir])
AS_AC_EXPAND([LIBDIR], [$libdir])
AS_AC_EXPAND([LIBEXECDIR], [$libexecdir])
AS_AC_EXPAND([SCHEMADIR], [$PKGDATADIR/schemas])

AC_DEFINE_UNQUOTED(PKGDATADIR, "$PKGDATADIR", [Package base directory])
AC_DEFINE_UNQUOTED(SCHEMAFILEDIR, "$SCHEMADIR", [Directory with config schema])
AC_DEFINE_UNQUOTED(DATADIR, "$DATADIR", [Data directory])

dnl {{{ enable debug release configuration
AC_ARG_ENABLE(debug,
	AC_HELP_STRING([--enable-debug],
		[Use 'DEBUG' Configuration [default=YES]]),
		enable_debug=yes, enable_debug=no)
AM_CONDITIONAL(ENABLE_DEBUG, test "x$enable_debug" = "xyes")
if test "x$enable_debug" = "xyes" ; then
	CONFIG_REQUESTED="yes"
fi
dnl }}}

dnl {{{ enable release build configuration
AC_ARG_ENABLE(release,
	AC_HELP_STRING([--enable-release],
		[Use 'RELEASE' Configuration [default=NO]]),
		enable_release=yes, enable_release=no)
AM_CONDITIONAL(ENABLE_RELEASE, test x$enable_release = xyes)
if test "x$enable_release" = "xyes" ; then
	CONFIG_REQUESTED="yes"
fi
if test -z "$CONFIG_REQUESTED" ; then
	AM_CONDITIONAL(ENABLE_DEBUG, true)
fi
dnl }}}

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
data/themes/Matte/Makefile
data/themes/Transparent/Makefile
m4/Makefile
man/Makefile
Plank/Makefile
po/Makefile.in
vapi/Makefile
])

AC_OUTPUT

cat <<EOF

${PACKAGE}-${VERSION}

  Build Environment
    Install Prefix:     ${prefix}
      Use GTK+ API:     ${GTK_API_VERSION}

  Build/Development
    Release Build:      ${enable_release}

EOF
