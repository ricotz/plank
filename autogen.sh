#!/bin/sh
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="plank"

(test -f $srcdir/configure.ac \
  && test -f $srcdir/autogen.sh) || {
    echo -n "**Error**: Directory \`$srcdir' does not look like the"
    echo " top-level $PKG_NAME directory"
    exit 1
}

if which gnome-autogen.sh ; then
  REQUIRED_AUTOMAKE_VERSION=1.9 . gnome-autogen.sh
else
  if which intltoolize && which autoreconf ; then
    intltoolize --copy --force --automake || \
      (echo "There was an error in running intltoolize." > /dev/stderr;
       exit 1)
    autoreconf --force --install || \
      (echo "There was an error in running autoreconf." > /dev/stderr;
       exit 1)
  else
    echo "No build script available.  You have two choices:"
    echo "1. You need to install the gnome-common module and make"
    echo "   sure the gnome-autogen.sh script is in your \$PATH."
    echo "2. You need to install the following scripts:"
    echo "   * intltool"
    echo "   * libtool"
    echo "   * automake"
    echo "   * autoconf"
    echo "   Additionally, you need to make"
    echo "   sure that they are in your \$PATH."
    exit 1
  fi
fi

