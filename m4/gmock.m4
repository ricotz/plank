#
#  Copyright (C) 2015 Rico Tzschichholz
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  Checks for existence of google-mock headers and sources,
#      as for google-test headers and sources:
#
AC_DEFUN([AC_GMOCK],
[
    AC_ARG_ENABLE(gmock,
        [AS_HELP_STRING([--enable-gmock], [Enable testing with google-mock and google-test])],
        [use_gmock=$enableval], [use_gmock=no])

    AC_ARG_WITH(gmock-path,
        [AS_HELP_STRING([--with-gmock-path], [Absolute path to the google-mock source folder])],
        [GMOCK_SRCDIR="$withval" GMOCK_INCLUDEDIR="$withval"],
        [GMOCK_SRCDIR="/usr/src/gmock" GMOCK_INCLUDEDIR="/usr/include"])

    AC_ARG_WITH(gtest-path,
        [AS_HELP_STRING([--with-gtest-path], [Absolute path to the google-test source folder])],
        [GTEST_SRCDIR="$withval" GTEST_INCLUDEDIR="$withval"],
        [GTEST_SRCDIR="/usr/src/gtest" GTEST_INCLUDEDIR="/usr/include"])

    AM_CONDITIONAL(HAVE_GMOCK, test "x$use_gmock" = "xyes")

    if test "x$use_gmock" = "xyes"; then
        AC_SUBST([GMOCK_SRCDIR])
        AC_SUBST([GMOCK_INCLUDEDIR])
        AC_SUBST([GTEST_SRCDIR])
        AC_SUBST([GTEST_INCLUDEDIR])

        # Remove all optimization flags from CFLAGS and CXXFLAGS
        changequote({,})
        CFLAGS=`echo "$CFLAGS" | $SED -e 's/-O[0-9]*//g'`
        CXXFLAGS=`echo "$CXXFLAGS" | $SED -e 's/-O[0-9]*//g'`
        changequote([,])
    fi
]) # AC_GMOCK
