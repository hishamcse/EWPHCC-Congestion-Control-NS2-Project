set ns [new Simulator]
$ns rtproto Static

###########################################################################
# Global configuration parameters                                         #
###########################################################################

HandoffManager/Term set elevation_mask_ 8.2
HandoffManager/Term set term_handoff_int_ 10
HandoffManager set handoff_randomization_ false

global opt
set opt(chan)           Channel/Sat
set opt(bw_down)	    1.5Mb; # Downlink bandwidth (satellite to ground)
set opt(bw_up)		    1.5Mb; # Uplink bandwidth
set opt(bw_isl)		    25Mb
set opt(phy)            Phy/Sat
set opt(mac)            Mac/Sat
set opt(ifq)            Queue/DropTail
set opt(qlim)		    50
set opt(ll)             LL/Sat
set opt(wiredRouting)	ON

# Define variable Parameters
set val(node_count)     [lindex $argv 0]        ;# number of nodes

set opt(alt)		    [lindex $argv 1]    ;# Polar satellite altitude (Iridium)
set opt(inc)		    90                  ;# Orbit inclination w.r.t. equator

set option              [lindex $argv 2]        ;# tcp or tcp-vegas

set outfile [open trace.tr w]
$ns trace-all $outfile

###########################################################################
# Set up satellite and terrestrial nodes                                  #
###########################################################################

# Let's first create a single orbital plane of Iridium-like satellites
# 11 satellites in a plane

# Set up the node configuration

$ns node-config -satNodeType polar \
		-llType $opt(ll) \
		-ifqType $opt(ifq) \
		-ifqLen $opt(qlim) \
		-macType $opt(mac) \
		-phyType $opt(phy) \
		-channelType $opt(chan) \
		-downlinkBW $opt(bw_down) \
		-wiredRouting $opt(wiredRouting)

# Create nodes n0 through n10
for {set i 0} {$i < $val(node_count)} {incr i} {
	set n($i) [$ns node]
}

# Now provide position information for each of these nodes
# Position arguments are: altitude, incl., longitude, "alpha", and plane
# See documentation for definition of these fields
set ang_dist [ expr 360.0/$val(node_count) ]
set plane 1
for {set i 0} {$i < $val(node_count)} {incr i} {
	$n($i) set-position $opt(alt) $opt(inc) 0 [expr ($i * $ang_dist)] $plane
}

# This next step is specific to polar satellites
# By setting the next_ variable on polar sats; handoffs can be optimized  
# This step must follow all polar node creation
for {set i 0} {$i < $val(node_count)} {incr i} {
	set next [expr ($i - 1 + $val(node_count)) % $val(node_count)]
	$n($i) set_next $n($next)
}

# GEO satellite:  above North America-- lets put it at 100 deg. W
$ns node-config -satNodeType geo
set n11 [$ns node]
$n11 set-position -100

# Terminals:  Let's put two within the US, two around the prime meridian
$ns node-config -satNodeType terminal 
set n100 [$ns node]; set n101 [$ns node]
$n100 set-position 37.9 -122.3; # Berkeley
$n101 set-position 42.3 -71.1; # Boston
set n200 [$ns node]; set n201 [$ns node]
$n200 set-position 0 10 
$n201 set-position 0 -10

###########################################################################
# Set up links                                                            #
###########################################################################

# Add any necessary ISLs or GSLs
# GSLs to the geo satellite:
$n100 add-gsl geo $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n11 set downlink_] [$n11 set uplink_]
$n101 add-gsl geo $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n11 set downlink_] [$n11 set uplink_]
# Attach n200 and n201 initially to a satellite on other side of the earth
# (handoff will automatically occur to fix this at the start of simulation)
$n200 add-gsl polar $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n(5) set downlink_] [$n(5) set uplink_]
$n201 add-gsl polar $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n(5) set downlink_] [$n(5) set uplink_]

# ISLs for the polar satellites
for {set i 0} {$i < $val(node_count)} {incr i} {
	$ns add-isl intraplane $n($i) $n([expr ($i + 1) % $val(node_count)]) \
		$opt(bw_isl) $opt(ifq) $opt(qlim)
}


###########################################################################
# Set up wired nodes                                                      #
###########################################################################
# Connect $n300 <-> $n301 <-> $n302 <-> $n100 <-> $n11 <-> $n101 <-> $n303
#                      ^                   ^
#                      |___________________|    
#
# Packets from n303 to n300 should bypass n302 (node #18 in the trace)
# (i.e., these packets should take the following path:  19,13,11,12,17,16)
#
$ns unset satNodeType_
set n300 [$ns node]; # node 16 in trace
set n301 [$ns node]; # node 17 in trace
set n302 [$ns node]; # node 18 in trace
set n303 [$ns node]; # node 19 in trace
$ns duplex-link $n300 $n301 5Mb 2ms DropTail; # 16 <-> 17
$ns duplex-link $n301 $n302 5Mb 2ms DropTail; # 17 <-> 18
$ns duplex-link $n302 $n100 5Mb 2ms DropTail; # 18 <-> 11
$ns duplex-link $n303 $n101 5Mb 2ms DropTail; # 19 <-> 13
$ns duplex-link $n301 $n100 5Mb 2ms DropTail; # 17 <-> 11


###########################################################################
# Tracing                                                                 #
###########################################################################
$ns trace-all-satlinks $outfile

###########################################################################
# Attach agents                                                           #
###########################################################################

if {$option == 1} {
	set tcp0 [new Agent/TCP]
	set tcp1 [new Agent/TCP]
	set tcp2 [new Agent/TCP]
} else {
	set tcp0 [new Agent/TCP/Vegas]
	set tcp1 [new Agent/TCP/Vegas]
	set tcp2 [new Agent/TCP/Vegas]
}

$ns attach-agent $n100 $tcp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 attach-agent $tcp0
$cbr0 set interval_ 60.01

$ns attach-agent $n200 $tcp1
$tcp1 set class_ 1
set cbr1 [new Application/Traffic/CBR]
$cbr1 attach-agent $tcp1
$cbr1 set interval_ 90.5

set null0 [new Agent/Null]
$ns attach-agent $n101 $null0
set null1 [new Agent/Null]
$ns attach-agent $n201 $null1

$ns connect $tcp0 $null0
$ns connect $tcp1 $null1

###########################################################################
# Set up connection between wired nodes                                   #
###########################################################################
$ns attach-agent $n303 $tcp2
set cbr2 [new Application/Traffic/CBR]
$cbr2 attach-agent $tcp2
$cbr2 set interval_ 300
set null2 [new Agent/Null]
$ns attach-agent $n300 $null2

$ns connect $tcp2 $null2
$ns at 10.0 "$cbr2 start"

###########################################################################
# Satellite routing                                                       #
###########################################################################

set satrouteobject_ [new SatRouteObject]
$satrouteobject_ compute_routes
#$satrouteobject_ set wiredRouting_ true

$ns at 1.0 "$cbr0 start"
$ns at 305.0 "$cbr1 start"
#$ns at 0.9 "$cbr1 start"

$ns at 9000.0 "finish"

proc finish {} {
	global ns outfile 
	$ns flush-trace
	close $outfile

	exit 0
}

$ns run

