default: pkgIndex.tcl

TCLLIST:=density_profile_gui.tcl density_profile.tcl density_profile_init.tcl
DISTLIST:=COPYRIGHT INSTALL pkgIndex.tcl
VMD_PLUGIN_DIR=density_profile

dist:
	rm -rf $(VMD_PLUGIN_DIR)
	mkdir $(VMD_PLUGIN_DIR)
	cp $(DISTLIST) $(VMD_PLUGIN_DIR)
	for f in $(TCLLIST); do \
		cat COPYRIGHT $$f > $(VMD_PLUGIN_DIR)/$$f ; \
	done 
	tar -zcvf  $(VMD_PLUGIN_DIR).tgz  $(VMD_PLUGIN_DIR)


