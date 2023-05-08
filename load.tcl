set density_profile_dir [file dirname [file normalize [info script]]]

puts "density_profile) Adding directory $density_profile_dir to auto_path and registering the menu"

lappend auto_path $density_profile_dir
package require density_profile_gui
::density_profile_gui::register_menu
