#!/usr/bin/expect

if { [info globals istest] == "" } { set istest "" }
set hosts			{}
set named_hosts		{}
set prompt			{[][$|\\#><%]{1,}($| $)}
set rsync_option 	""
set timeout			600000

proc sync { reverse name opt src dst { exc "" } } {
	global prompt
	global hosts named_hosts
	global rsync_option
	global istest
	set host $hosts

	if { $istest != "" } { 
		puts "____               ____              "
		puts "|  _ \\ _ __ _   _  |  _ \\ _   _ _ __  "
		puts "| | | | '__| | | | | |_) | | | | '_ \\ "
		puts "| |_| | |  | |_| | |  _ <| |_| | | | |"
		puts "|____/|_|   \\__, | |_| \\_\\\\__,_|_| |_|"
		puts "            |___/                     "
		set rsync_option [ format "$rsync_option --dry-run" ] 
	}

	for { set i 0 } { $i < [llength $named_hosts] } { incr i } {
		set info 	[lindex $named_hosts $i]
		set n 		[lindex $info 0]
		set h 		[lindex $info 1]
		if { "$n" == "$name" } { set host $h; break; }
	}

	for { set i 0 } { $i < [llength $host] } { incr i } {
		set info		[lindex $host $i]
		set ipaddr		[lindex $info 0]
		set port		[lindex $info 1]
		set passwd		[lindex $info 2]

		if { [file exists ${src}/.include.sync.${name}] == 1 } {
			puts [ format ".include.sync.${name} exist" ]
			set exc [ format "$exc --include-from=${src}/.include.sync.${name}" ]
		} else {
			if { [file exists ${src}/.include.sync] == 1 } {
				puts [ format ".include.sync exist" ]
				set exc [ format "$exc --include-from=${src}/.include.sync" ]
			}
		}
		if { [file exists ${src}/.exclude.sync.${name}] == 1 } {
			puts [ format ".exclude.sync.${name} exist" ]
			set exc [ format "$exc --exclude-from=${src}/.exclude.sync.${name}" ]
		} else {
			if { [file exists ${src}/.exclude.sync] == 1 } {
				puts [ format ".exclude.sync exist" ]
				set exc [ format "$exc --exclude-from=${src}/.exclude.sync" ]
			}
		}

		if { $i > 0 } { puts ".........................................................." }
		puts -nonewline "Sync ${name} to ${ipaddr}\n  " 
		if { $reverse == 0 } {
			eval spawn -noecho rsync -az ${rsync_option} ${opt} -e \"ssh -p $port\" ${exc} ${src} ${ipaddr}:${dst} 
		} else {
			eval spawn -noecho rsync -az ${rsync_option} ${opt} -e \"ssh -p $port\" ${exc} ${ipaddr}:${dst} ${src} 
		}
	
		expect {
			-re "assword" { send ${passwd}; send "\r"; exp_continue }
			-re "Are you" { send "yes\r"; exp_continue }
			-re "Permission denied" { continue }
			-re $prompt { exp_break }
		}	
	}
	puts "========================================================="
}

proc _sync_dir { reverse name opt src dst args } {
	global argc, argv
	if { $argv == "" || [lindex $argv 0] == $name } {
		set exc ""
		foreach arg ${args} {
			set exc [ format "$exc --exclude \"$arg\"" ]
		}
		sync $reverse $name $opt $src $dst $exc
	}
}
proc sync_dir { name opt src dst args } {
	eval _sync_dir 0 $name $opt $src $dst $args
}
proc rsync_dir { name opt src dst args } {
	eval _sync_dir 1 $name $opt $src $dst $args
}
proc sync_file { name opt src dst args } {
	global argc, argv
	if { $argv == "" || [lindex $argv 0] == $name } {
		set files ""
		foreach arg "${args}" {
			set files [ format "$files $src/$arg" ]
		}
		sync 0 $name $opt $files $dst
	}
}
proc rsync_file { name opt src dst args } {
	global argc, argv
	if { $argv == "" || [lindex $argv 0] == $name } {
		set tmpfile "XfjdDjfdEZfjefF"	
		set files [format "--files-from=$tmpfile"]
		set f [open $tmpfile w+]
		foreach arg $args { puts $f $arg }
		close $f
		eval sync 1 $name $opt $src $dst $files
		exec rm $tmpfile
	}
}
