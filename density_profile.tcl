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

    # Atom numbers - only the first letter counts
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
    puts "VMD Density Profile tool.  Computes 1-D projections of various atomic densities."
    puts "The computation is performed in a single frame, a trajectory, or averaged"
    puts "over multiple frames. You probably want to wrap your trajectory."
    puts "See http://multiscalelab.org/utilities/DensityProfileTool"
    puts " "
    puts "Usage: density_profile <args>"
    puts "Args (with defaults):"
    foreach k $dp_args_list {
	puts "   -$k $dp_args($k)"
    }
}


# Command line parsing (sets namespace variables). TODO: allow short
# substrings, e.g. -sel
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


# Main entry point. 
proc ::density_profile::density_profile {args} {
    variable dp_args
    if {[llength $args]==0} {
	density_profile_usage
	return
    } 
    eval density_profile_parse $args

    parray dp_args

    # Reformat the histogram and return it
    set lhist [compute]
    set xbreaks [hist_to_xbreaks $lhist]
    set framelist [hist_to_frames $lhist]
    set values [hist_to_values $lhist]

    # If averaging or single-frame, flatten inner list
    if { $dp_args(average)==1 || [llength $framelist]==1 } {
	set values [average_sublists $values]
    }

    return [list $values $xbreaks]

}


# Convert histogram into lists of values.  If resolution=2 and
#  hist(2,-3)=0.23   ; hist(2,-1)=0.21;
#  hist(4,-2)=0.42   ; hist(4,0)=0.40 =>

# Convert histogram into list of breaks => {-6, -4, -2, 0}
proc ::density_profile::hist_to_xbreaks {lhist} {
    variable dp_args
    array set hist $lhist
    lassign [get_keys_range [array names hist]] fmin fmax binmin binmax

    set xbreaks {}
    for {set bin $binmin} {$bin<=$binmax} {incr bin} {
	lappend xbreaks [expr $bin*$dp_args(resolution)]
    }
    return $xbreaks
}

# Convert histogram into list of frames => { 2,4 }
proc ::density_profile::hist_to_frames {lhist} {
    array set hist $lhist
    set kk [array names hist]
    foreach k $kk {
	lappend flist [lindex [split $k ,] 0]
	lappend xlist [lindex [split $k ,] 1]
    }
    set flist [lsort -uniq -integer $flist]
    return $flist
}


# Values, return { {0.23 0} {0 0.42} {0.21 0} {0 0.40} }
proc ::density_profile::hist_to_values {lhist} {
    variable dp_args
    array set hist $lhist
    lassign [get_keys_range [array names hist]] fmin fmax binmin binmax

    # Outer cycle is on bins
    set v {}
    set nbins [expr $binmax-$binmin+1]

    for {set idx 0} {$idx<$nbins} {incr idx} {
	set bin [expr $idx+$binmin]
	set tmp {}
	# Inner cycle on frames
	for {set f $fmin} {$f<=$fmax} {incr f} {
	    lappend tmp $hist($f,$bin)
	}
	lappend v $tmp
    }
    return $v
}


# Average sublists: { {0.23 0} {0 0.42} {0.21 0} {0 0.40} } -> { 0.125
# 0.21 0.105 0.20 }. Also useful for flattening in case of one frame
proc ::density_profile::average_sublists {vl} {
    set res {}
    foreach l $vl {
	lappend res [vecmean $l]
    }
    return $res
}




# Compute and return the bare histogram. Relation between bins and coordinate is implicit;
#  - note that [0..$resolution) goes in bin 0, and so on.
#
#  bin = [expr int(floor($x/$resolution))] 
#  xmin = $bin * $resolution
#
#  hist(frame,bin)
#
# The hist structure is contrieved because we don't know the bins
# until all of the frames have been scanned

proc ::density_profile::compute { } {
    variable dp_args

    set resolution $dp_args(resolution)
    set axis $dp_args(axis)

    # Check if PBC box is set
    set area [transverse_area]
    if { $area == -1 } { 	
	puts "Warning: No periodic cell information. Will compute linear densities instead of volume densities."
	set area 1
    } elseif { $area == -2 } {
	error "Only orthorombic cells are supported"
    }
    
    # Values
    set tval [get_values]
    set tval [vecscale [expr 1./$area/$resolution] $tval]

    # Frame range
    lassign [fix_frame_range] ffrom fto fstep

    # Start loop over frames
    set as [atomselect top $dp_args(selection)]
    array unset hist
    for {set f $ffrom} {$f<=$fto} {incr f $fstep} {
	$as frame $f
	set xval [$as get $axis]

	# make histogram: hist(frame,bin)
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



# Sanity check on PBC. Return -1 if error occurred but densities can
# be still computed, -2 if not, else return transversal PBC area 
proc ::density_profile::transverse_area { } {
    variable dp_args
    lassign [molinfo top get {a b c alpha beta gamma}] a b c alpha beta gamma

    # heuristic for unset box
    if {$a<2 || $b<2 || $c<2} {	
	return -1
    } elseif {$alpha!= 90 || $beta!=90 || $gamma!=90} {
	return -2
    } else {
	switch -- $dp_args(axis) {
	    x { set area [expr $b*$c] }
	    y { set area [expr $a*$c] }
	    z { set area [expr $a*$b] }
	}
	return $area
    }
}


# return the range over the 1st and 2nd dimension of a pseudo-2d array
# e.g. {2,3 5,4 2,4} -> {2 5 3 4}
# 
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
# 
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


# Auxiliary function, returns {from to step}, after possibly fixing
# "now"
proc ::density_profile::fix_frame_range {} {
    variable dp_args
    set f $dp_args(frame_from)
    set t $dp_args(frame_to)
    set s $dp_args(frame_step)

    # Should be the atom selection frame?
    if { $f=="now" } { set f [molinfo top get frame] }
    if { $t=="now" } { set t [molinfo top get frame] }

    return [list $f $t $s]
}


# Return the values of the selected property, as a list of one value
# per selected atom. These will not change per-frame.
# 
proc ::density_profile::get_values {} {
    variable dp_args
    set as [atomselect top $dp_args(selection)]
    switch $dp_args(target) {
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
	    if {$dp_args(partial_charges)==1} {
		set pch [$as get charge]
		set tval [vecadd $tval $pch]
	    }
	}
    }
    $as delete
    return $tval
}


# Similar to [atomselect get ...] , but get Z number, based on the
# $ansource attribute and name_to_Z table.
proc ::density_profile::getZ {as} {
    variable dp_args
    variable name_to_Z

    set nlist [$as get $dp_args(ansource)]
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
