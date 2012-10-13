#! /bin/sh

cpp -P -DG_OS_UNIX ${srcdir:-.}/libplank.symbols \
	| sed -e '/^$/d' -e 's/ G_GNUC.*$//' -e 's/ PRIVATE//' -e 's/ DATA//' \
	| sort > expected-abi

nm -D -g --defined-only .libs/libplank.so \
	| cut -d ' ' -f 3 \
	| egrep -v '^(__bss_start|_edata|_end)' \
	| sort > actual-abi

diff -u expected-abi actual-abi || true && rm -f expected-abi actual-abi
