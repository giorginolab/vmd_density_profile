VMD Density Profile Tool v 1.1
========================================

13-May-2013

The Density Profile Tool is a VMD [1] analysis plugin that computes
1-D projections of various atomic densities. The computation may be
performed in a single frame, a trajectory, or averaged over multiple
frames.

 *  Number density, i.e. average number of atoms per unit volume
 *  Mass density
 *  Charge density
 *  Electron density, i.e. average number of electrons. 


Check the current version of software and documentation at:
    http://multiscalelab.org/utilities/DensityProfileTool


Please cite this paper when publishing
results obtained with the Density Profile Tool:

    Toni Giorgino, Computing 1-D atomic densities in macromolecular
	simulations: the Density Profile Tool for VMD, Computer 
	Physics Communications (XX-XXX).


[1] Visual Molecular Dynamics (VMD), http://www.ks.uiuc.edu/Research/vmd/


Author
----------------------------------------
Toni Giorgino
Institute of Biomedical Engineering (ISIB)
National Research Council of Italy (CNR)
toni.giorgino at isib.cnr.it




Installation
----------------------------------------
Please see instructions provided in INSTALL.txt 



Quickstart
----------------------------------------
Once correctly installed, a menu item should appear in VMD's
Extensions menu, under "Extensions>Analysis>Density Profile Tool".

The plugin can be used interactively or via a scripting interface. See
the included test script (example.tcl) for an example of in-script
usage. The script 

1. loads Klauda's equilibrated membranes
   (http://terpconnect.umd.edu/~jbklauda/research/download.html), POPC
   Bilayer (303.00K, NPT, 35ns, 72 lipids);
2. computes the mass density profile for water molecules, showing
   it as a table and a plot;
3. computes the electron density profile for the whole system, showing
   it as a plot.

Sample output for point 2.:

	| Bin breaks coordinates: (z, Angstroms)
		| Density of water in each bin: (g/mol/A^3)
	 -35.00	  0.00
	 -34.00	  0.28
	 -33.00	  0.65
	 -32.00	  0.61
	 -31.00	  0.62
	 -30.00	  0.60
	 -29.00	  0.62
	 -28.00	  0.56
	 -27.00	  0.56
	 -26.00	  0.61
	 -25.00	  0.55
	[...]
	  28.00	  0.58
	  29.00	  0.64
	  30.00	  0.56
	  31.00	  0.57
	  32.00	  0.60
	  33.00	  0.25
	  34.00	  0.00


	


Description of the included files
----------------------------------------
density_profile.tcl		Core functions and command line interface 
density_profile_gui.tcl		Functions providing the graphical user
				interface (GUI)
density_profile_init.tcl	Require loading the GUI (meant to run 
				at VMD startup)
example.tcl			Example of use in scripting (see above)





