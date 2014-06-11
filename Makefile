.SILENT:

VMFILES = pkgIndex.tcl diffusion_coefficient_gui.tcl diffusion_coefficient_gui_ui.tcl diffusion_coefficient.tcl
VMVERSION = 1.2
DIR = $(PLUGINDIR)/noarch/tcl/diffusion_coefficient(VMVERSION)


bins:
win32bins:
dynlibs:
staticlibs:
win32staticlibs:

distrib:
	@echo "Copying diffusion_coefficient $(VMVERSION) files to $(DIR)"
	mkdir -p $(DIR) 
	cp $(VMFILES) $(DIR) 
