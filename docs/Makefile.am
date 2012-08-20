distclean_dirs = \
	plank \
	gtk-doc \
	$(NULL)

phony_deps = \
	plank-doc \
	plank-gtk-doc \
	$(NULL)

plankdocdir=$(datadir)/devhelp/references/plank
plankimgdir=$(datadir)/devhelp/references/plank/img
plankgtkdocdir=$(datadir)/gtk-doc/html/plank

common_doc_files = \
	*.css \
	*.png \
	*.js \
	index.htm \
	*.html \
	$(NULL)

plankdoc_DATA = \
	plank/plank/plank.devhelp2 \
	$(addprefix plank/plank/,$(common_doc_files)) \
	$(NULL)

plankgtkdoc_DATA = gtk-doc/plank/html/*

plankimg_DATA = \
	plank/plank/img/*.png \
	$(NULL)

$(plankdoc_DATA) $(plankimg_DATA): plank-doc
$(plankgtkdoc_DATA): plank-gtk-doc

valadoc_flags = \
	--force \
	--verbose \
	--package-name $(PACKAGE_NAME) \
	--package-version $(PACKAGE_VERSION) \
	$(NULL)

# plank documentation
plank_doc_files = \
	$(top_srcdir)/lib/*.vala \
	$(top_srcdir)/lib/Drawing/*.vala \
	$(top_srcdir)/lib/Factories/*.vala \
	$(top_srcdir)/lib/Items/*.vala \
	$(top_srcdir)/lib/Services/*.vala \
	$(top_srcdir)/lib/Widgets/*.vala \
	$(NULL)

plank_doc_deps = \
	gee-1.0 \
	gio-unix-2.0 \
	gdk-x11-3.0 \
	gtk+-3.0 \
	libbamf3 \
	libwnck-3.0 \
	posix \
	x11 \
	$(NULL)

valadoc_flags_plank = \
	$(valadoc_flags) \
	-X $(top_srcdir)/lib/plank.h \
	$(addprefix --pkg=,$(plank_doc_deps)) \
	--vapidir=$(top_srcdir)/lib \
	--vapidir=$(top_srcdir)/vapi \
	$(plank_doc_files) \
	$(NULL)

plank-doc: $(plank_doc_files)
	$(AM_V_GEN)$(VALADOC) \
		-o plank/ \
		--doclet=html \
		$(valadoc_flags_plank) \
		$(NULL)

plank-gtk-doc: $(plank_doc_files)
	$(AM_V_GEN)$(VALADOC) \
		-X -l -X $(top_builddir)/lib/.libs/libplank.so \
		-o gtk-doc/plank \
		--doclet=gtkdoc \
		$(valadoc_flags_plank) \
		$(NULL)

.PHONY: $(phony_deps)

distclean-local: distclean-docs
distclean-docs:
	rm -rf $(distclean_dirs)

