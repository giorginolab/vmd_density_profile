VMD Density Profile Tool
========================================


The Density Profile Tool is a VMD [1] analysis plugin that computes
1-D projections of various atomic densities. The computation may be
performed in a single frame, a trajectory, or averaged over multiple
frames.

 *  Number density, i.e. average number of atoms per unit volume
 *  Mass density
 *  Charge density
 *  Electron density, i.e. average number of electrons. 

[1] Visual Molecular Dynamics (VMD), http://www.ks.uiuc.edu/Research/vmd/


Author
----------------------------------------
Toni Giorgino <br>
National Research Council of Italy (CNR)  <br>
toni.giorgino at cnr.it



Citation
----------------------------------------

Please cite this paper when publishing results obtained with the
Density Profile Tool:

 *  Giorgino T. *Computing 1-D atomic densities in macromolecular
    simulations: The density profile tool for VMD.* Computer Physics
    Communications. 2014 Jan;185(1):317–22. Available from
    [doi:10.1016/j.cpc.2013.08.022](https://www.sciencedirect.com/science/article/pii/S0010465513002956)
    or preprint at [arXiv:1308.5873](https://arxiv.org/abs/1308.5873)



Installation
----------------------------------------

See instructions [here](https://gist.github.com/tonigi/a9cfaf7642a7fbc13293).




	
Documentation
---------------------

Further documentation is available in the `doc` subdirectory.

For an extensive description of the tool, together with the comparison
with experimental data, see the [Density Profile paper](http://www.sciencedirect.com/science/article/pii/S0010465513002956) 






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

~~~~~~
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
~~~~~~



License
---------------

Density Profile Plugin
Copyright (C) 2012 

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
