.SILENT:

VMFILES = pkgIndex.tcl density_profile_gui.tcl density_profile_gui_ui.tcl density_profile.tcl
VMVERSION = 1.2
DIR = $(PLUGINDIR)/noarch/tcl/density_profile(VMVERSION)


bins:
win32bins:
dynlibs:
staticlibs:
win32staticlibs:

distrib:
	@echo "Copying density_profile $(VMVERSION) files to $(DIR)"
	mkdir -p $(DIR) 
	cp $(VMFILES) $(DIR) 
