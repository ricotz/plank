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
	--package-version $(PACKAGE_VERSION) \
	$(NULL)

# plank documentation
plank_doc_files = \
	$(top_srcdir)/lib/*.vala \
	$(NULL)

plank_doc_deps = \
	gconf-2.0 \
	gmodule-2.0 \
	gio-2.0 \
	gee-1.0 \
	bamf \
	wnck-1.0 \
	$(NULL)

valadoc_flags_plank = \
	$(valadoc_flags) \
	-X $(top_srcdir)/lib/plank.h \
	$(addprefix --pkg=,$(plank_doc_deps)) \
	--vapidir=$(top_srcdir)/lib \
	$(plank_doc_files) \
	$(NULL)

plank-doc: $(plank_doc_files)
	$(AM_V_GEN)$(VALADOC) \
		-o plank/ \
		--doclet=devhelp \
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

