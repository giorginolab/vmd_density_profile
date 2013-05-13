# Test script for the Density Profile Plugin

# The script can also be used from the GUI (VMD Main
# window->Extensions->Analysis->Density Profile Tool). This script
# only illustrates the command-line interface.



# Initialization: load Klauda's equilibrated membranes,
#  http://terpconnect.umd.edu/~jbklauda/research/download.html POPC
#  Bilayer (303.00K, NPT, 35ns, 72 lipids): PDB, CHARMM PSF, CHARMM36
#  Current directory needs be writable.

mol delete all
vmd_mol_urlload  http://terpconnect.umd.edu/~jbklauda/research/download/popc72-c36npt.pdb popc72-c36npt.pdb
vmd_mol_urlload  http://terpconnect.umd.edu/~jbklauda/research/download/popc72-c36npt.psf popc72-c36npt.psf
mol new popc72-c36npt.psf waitfor all
mol addfile popc72-c36npt.pdb waitfor all
pbc set { 48.4331 48.4331 66.913 }; # Set box size


# Define a convenience function to pretty-print two lists
proc pptable {l1 l2} { foreach i1 $l1 i2 $l2 { puts " [format %6.2f $i1]\t[format %6.2f $i2]" }  }



# Begin analysis

# - Load package
package require density_profile

# - Compute mass density for water molecules only
set wdens [density_profile -rho mass -selection water]

# - In $wdens we now have
# index 0: list of densities [g/mol/A^3]: from 0 (center) to ~0.6 (bulk)
# index 1: list of bin breaks [A]: -35, -34, ... 34

# - Show output as a table
puts "**************************************************"
puts "| Bin breaks coordinates: (z, Angstroms)"
puts "\t| Density of water in each bin: (g/mol/A^3)"
pptable [lindex $wdens 1] [lindex $wdens 0]


# - The same as plots (assume you have a graphics terminal)
multiplot -x [lindex $wdens 1] -y [lindex $wdens 0] -marker point -plot \
	-title "Water mass density (g/mol/A^3); dots: bulk value" \
	-xlabel "Distance from membrane center z (A)" \
	-hline {0.6 -dash .}



# - Compute the electron density of full system (small membrane, only
#   one frame: lower resolution); show graphically.
set edens [density_profile -rho electrons -selection all -resolution 2]
multiplot -x [lindex $edens 1] -y [lindex $edens 0] -marker point -plot \
	-title "Electron density (1/A^3); dots: value for bulk water" \
	-xlabel "Distance from membrane center z (A)" \
	-hline {0.33 -dash .}

