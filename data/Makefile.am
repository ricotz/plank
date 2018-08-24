NULL =

SUBDIRS = \
	icons \
	themes \
	$(NULL)

if ENABLE_APPORT
SUBDIRS += apport
endif

EXTRA_DIST = \
	application-default-icon.svg \
	plank.appdata.xml.in \
	net.launchpad.plank.gschema.xml.in \
	plank.desktop.in \
	plank.gresource.xml \
	poof.svg \
	ui/preferences.ui \
	$(NULL)

CLEANFILES = \
	plank.appdata.xml \
	plank.desktop \
	$(gsettings_SCHEMAS) \
	gschemas.compiled \
	net.launchpad.plank.gschema.valid \
	$(NULL)

applicationsdir = $(datadir)/applications
applications_DATA = plank.desktop

appdatadir = $(datadir)/metainfo
appdata_DATA = plank.appdata.xml

gsettings_SCHEMAS = net.launchpad.plank.gschema.xml

%.gschema.xml: %.gschema.xml.in Makefile
	$(AM_V_GEN) sed -e 's|@GETTEXT_PACKAGE[@]|$(GETTEXT_PACKAGE)|g' \
	$< > $@ || rm $@

@GSETTINGS_RULES@

gschemas.compiled: Makefile $(gsettings_SCHEMAS:.xml=.valid)
	$(AM_V_GEN) $(GLIB_COMPILE_SCHEMAS) --targetdir=$(builddir) $(builddir)

all-local: gschemas.compiled

%.desktop: %.desktop.in
	$(AM_V_GEN)$(MSGFMT) --desktop --keyword= --keyword=Name \
		--keyword=GenericName --keyword=Comment --keyword=Keywords \
		--template $< -d $(top_srcdir)/po -o $@

%.appdata.xml: %.appdata.xml.in
	$(AM_V_GEN)$(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@
