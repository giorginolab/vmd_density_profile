# Core functions for computing density profiles.



package provide density_profile 0.3

# Declare the namespace for this dialog
namespace eval ::density_profile:: {
    # Variables matching command line options
    variable dp_args
    array set dp_args {
	target          atoms
	selection       all
	axis            z
	resolution      1
	ansource        type
	partial_charges 1
	frame_from      now
	frame_to        now
	frame_step      1
	average		0
    }

    # Atom numbers
    variable name_to_Z {H 1  C 6  N 7  O 8  F 9  P 15  S 16}

    # List of args in "preferred" order
    variable dp_args_list {target selection axis resolution ansource partial_charges \
			       frame_from frame_to frame_step average}

}


# User-accessible proc
proc density_profile { args } { return [eval ::density_profile::density_profile $args] }


# Help
proc ::density_profile::density_profile_usage { } {
    variable dp_args
    variable dp_args_list
    puts "VMD Density Profile tool.  Computes 1-D projections of various atomic densities. "
    puts "The computation is performed in a single frame, a trajectory, or averaged over multiple frames."
    puts "See http://multiscalelab.org/utilities/DensityProfileTool"
    puts " "
    puts "Usage: density_profile <args>"
    puts "Args (with defaults):"
    foreach k $dp_args_list {
	puts "   -$k $dp_args($k)"
    }
}


# Command line parsing (sets namespace variables)
proc ::density_profile::density_profile_parse {args} {
    variable dp_args
    foreach {a v} $args {
	if {![regexp {^-} $a]} {
	    error "Argument should start with -: $a"
	} 
	set a [string trimleft $a -]
	if {![info exists dp_args($a)]} {
	    error "Unknown argument: $a"
	} 
	set dp_args($a) $v
    }
}


# Main entry point
proc ::density_profile::density_profile {args} {
    if {[llength $args]==0} {
	density_profile_usage
	return
    }

    variable dp_args
    eval density_profile_parse $args

    parray dp_args
}




# Get Z number from atomselection CORE
proc ::density_profile::getZ {as} {
    variable ansource
    variable name_to_Z

    set nlist [$as get $ansource]
    set res {}
    set unk {}
    set warns 0

    array set ztable $name_to_Z
    foreach n $nlist {
	set el [string range $n 0 0]
	if {[info exists ztable($el)]} {
	    set zn $ztable($el)
	} else {
	    if { ![info exists warn($n) ] } {
		puts "Error: unidentified atom $n"
		lappend unk $n
	    } 
	    set zn 0 
	}
	lappend res $zn
    }
    if {[llength $unk]>0} {
	error "Atomic numbers for the following $ansource keywords could not be inferred: $unk." 
    }
    return $res
}

# Sanity check on PBC. Return -1 if error occurred but densities can
# be still computed, -2 if not, else return transversal PBC area CORE
proc ::density_profile::assertpbc { } {
    variable axis
    lassign [molinfo top get {a b c alpha beta gamma}] a b c alpha beta gamma

    # heuristic for unset box
    if {$a<2 || $b<2 || $c<2} {	
	return -1
    } elseif {$alpha!= 90 || $beta!=90 || $gamma!=90} {
	return -2
    } else {
	switch -- $axis {
	    x { set area [expr $b*$c] }
	    y { set area [expr $a*$c] }
	    z { set area [expr $a*$b] }
	}
	return $area
    }
}


# return the range over the 1st and 2nd dimension of a pseudo-2d array
# e.g. {2,3 5,4 2,4} -> {2 5 3 4}
# CORE
proc ::density_profile::get_keys_range {kk} {    
    foreach k $kk {
	lappend flist [lindex [split $k ,] 0]
	lappend xlist [lindex [split $k ,] 1]
    }
    set flist [lsort -uniq -integer $flist]
    set xlist [lsort -uniq -integer $xlist]

    set fmin [lindex $flist 0]
    set fmax [lindex $flist end]
    set xmin [lindex $xlist 0]
    set xmax [lindex $xlist end]
    
    return [list $fmin $fmax $xmin $xmax]
}


# fill histogram keys so that there is one integer bin per each value
# between mi and max
# CORE
proc ::density_profile::fill_keys arr {
    upvar $arr inp
    lassign [get_keys_range [array names inp]] fmin fmax xmin xmax
    puts "Filling frames $fmin..$fmax, bins $xmin..$xmax"

    for {set f $fmin} {$f<=$fmax} {incr f} {
	for {set x $xmin} {$x<=$xmax} {incr x} {
	    if { ![info exists inp($f,$x)] } {
		set inp($f,$x) 0
	    }
	}
    }
}




# Fix frame range to current frame if not specified
# CORE
proc ::density_profile::fix_frame_range {} {
    variable frame_from;  variable frame_to; variable frame_step
    set fr [ list $frame_from $frame_to $frame_step ]
    if { $frame_from=="now" } { lset fr 0 [molinfo top get frame] }
    if { $frame_to=="now" } {   lset fr 1 [molinfo top get frame] }
    return $fr
}


# Return the values of the selected property, as a list of one value
# per selected atom. These will not change per-frame.
# CORE
proc ::density_profile::get_values {} {
    variable selection
    variable target
    variable partial_charges
    set as [atomselect top $selection]
    switch $target {
	atoms { 
	    set tval [lrepeat [$as num] 1] 
	}
	mass { 
	    set tval [$as get mass] 
	}
	charge { 
	    set tval [$as get charge] 
	}
	electrons { 
	    set tval [getZ $as]
	    if {$partial_charges==1} {
		set pch [$as get charge]
		set tval [vecadd $tval $pch]
	    }
	}
    }
    $as delete
    return $tval
}


proc ::density_profile::compute {} {

    # MOVE AWAY THIS CHECK
    set area [assertpbc]
    if { $area == -1 } { 	
	puts "No periodic cell information. Will compute linear densities instead of volume densities."
	set area 1
    } elseif { $area == -2 } {
	error "Only orthorombic cells are supported"
    }

    # Values
    set tval [get_values]
    set tval [vecscale [expr 1./$area/$resolution] $tval]

    # Frame range - REMOVE
    lassign [fix_frame_range] ffrom fto fstep


    # Start loop over frames
    set as [atomselect top $selection]
    array unset hist
    for {set f $ffrom} {$f<=$fto} {incr f $fstep} {
	$as frame $f
	set xval [$as get $axis]

	# make histogram - note that [0..$resolution) goes in bin 0, and so on
	foreach x $xval v $tval {
	    set bin [expr int(floor($x/$resolution))]
	    if {! [info exists hist($f,$bin)] } { set hist($f,$bin) 0 }
	    set hist($f,$bin) [expr $hist($f,$bin)+$v]
	}
    }
    $as delete
	
    # make bins for never-seen values
    fill_keys hist

    # Return histogram 
    return [array get hist]
}
