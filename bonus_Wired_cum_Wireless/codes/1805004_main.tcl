# ==================================
# Project : NS2 Simulation
# Syed Jarullah Hisham
# CSE' 18, Section A1
# ==================================
# Config :
# Connection type : Wired_cum_Wirelss
# Wireless MAC protocol : 802.11
# Routing protocol : DSDV
# Agent + Application : TCP-Vegas + CBR
# Node positioning : Random
# ==================================

# simulator
set ns [new Simulator]

$ns color 1 green
$ns color 2 Orange
$ns color 3 Red

# ======================================================================
# Define options

set val(chan)         Channel/WirelessChannel     ;# channel type
set val(prop)         Propagation/TwoRayGround    ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna         ;# Antenna type
set val(ll)           LL                          ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue     ;# Interface queue type
set val(ifqlen)       50                          ;# max packet in ifq
set val(netif)        Phy/WirelessPhy             ;# network interface type
set val(mac)          Mac/802_11                  ;# MAC type
set val(rp)           DSDV                        ;# ad-hoc routing protocol 
set val(area_size)    500                         ;# area size

# =======================================================================

# Define variable Parameters
set val(node_count)       [lindex $argv 0]        ;# number of nodes
set val(flow_count)       [lindex $argv 1]        ;# number of flows
set val(packet_count)     [lindex $argv 2]        ;# packet rate (packets/sec)

# Define wired_cum_wireless parameters
set wireless_nodes        10
set wired_nodes           [expr int($val(node_count) - $wireless_nodes)]

set bs1_X                 1.0
set bs1_Y                 2.0

set bs2_X                 100.0
set bs2_Y                 100.0


# Define hierarchical address
$ns node-config -addressType hierarchical
AddrParams set domain_num_ 3                       ;# number of domains (1 for wired, 1 for wireless)
lappend cluster_num 1 1 1                          ;# number of clusters in each domain
AddrParams set cluster_num_ $cluster_num
 
 ;# number of nodes in each cluster
lappend eilastlevel 100 25 1
AddrParams set nodes_num_ $eilastlevel            ;# for each domain


# Select option
set val(option)           [lindex $argv 3]        ;# option

# Define traffic parameters
set val(packet_type) 	  1
set val(packet_size) 	  4
set val(packet_rate)	  [expr $val(packet_size) * $val(packet_count)]

# trace file
set trace_file [open trace.tr w]
$ns trace-all $trace_file

# nam file
set nam_file [open animation.nam w]
$ns namtrace-all $nam_file

# topology: to keep track of node movements
set topo [new Topography]
$topo load_flatgrid $val(area_size) $val(area_size)

# general operation director for mobilenodes
create-god [expr $wireless_nodes + 2]

# random function
expr { srand(19) }
proc generateRandom {m mod a} {
    expr int($m * rand()) % $mod + $a
}

# create wired nodes and give hierarchial address
for {set j 0} {$j < $wired_nodes} {incr j} {
    set W($j) [$ns node "0.0.$j"]
}

# node configs
# ======================================================================

# $ns node-config -addressingType flat or hierarchical or expanded
#                  -adhocRouting   DSDV or DSR or TORA
#                  -llType	   LL
#                  -macType	   Mac/802_11
#                  -propType	   "Propagation/TwoRayGround"
#                  -ifqType	   "Queue/DropTail/PriQueue"
#                  -ifqLen	   50
#                  -phyType	   "Phy/WirelessPhy"
#                  -antType	   "Antenna/OmniAntenna"
#                  -channelType    "Channel/WirelessChannel"
#                  -topoInstance   $topo
#                  -energyModel    "EnergyModel"
#                  -initialEnergy  (in Joules)
#                  -rxPower        (in W)
#                  -txPower        (in W)
#                  -agentTrace     ON or OFF
#                  -routerTrace    ON or OFF
#                  -macTrace       ON or OFF
#                  -movementTrace  ON or OFF

# ======================================================================

$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -topoInstance $topo \
                -channelType $val(chan) \
                -agentTrace ON \
                -routerTrace OFF \
                -macTrace OFF \
                -movementTrace OFF \
                -wiredRouting ON \


# create base station node
set BS(0) [$ns node 1.0.0]
set BS(1) [$ns node 2.0.0]
$BS(0) random-motion 0             ;# disable random motion
$BS(1) random-motion 0             ;# disable random motion

# base-station Positioning : fixed
$BS(0) set X_ $bs1_X
$BS(0) set Y_ $bs1_Y
$BS(0) set Z_ 0

$BS(1) set X_ $bs2_X
$BS(1) set Y_ $bs2_Y
$BS(1) set Z_ 0

# create wireless nodes
for {set i 0} {$i < $wireless_nodes } {incr i} {
    set no [expr $i + 1]
    set node($i) [$ns node "1.0.$no"]
    $node($i) base-station [AddrParams addr2id [$BS(0) node-addr]]

    # Node size
    $ns initial_node_pos $node($i) 10
}

# setup wired connection
for {set i 0} {$i < $wired_nodes} {incr i} {
    set to [expr ($i+1)%$wired_nodes]
    $ns duplex-link $W($i) $W($to) 1Mb 2ms DropTail
}


$ns duplex-link $W(1) $BS(0) 1Mb 2ms DropTail
$ns duplex-link $W(1) $BS(1) 1Mb 2ms DropTail

# create flows
for {set i 0} {$i < $val(flow_count)} {incr i} {

    # Traffic config

    if { $val(option) == 1 } {
        set tcp($i) [new Agent/TCP]                       ;# create agent
    } else {
        set tcp($i) [new Agent/TCP/Vegas]                 ;# create agent
    }

    set tcp_sink($i) [new Agent/TCPSink]                  ;# create sink agent

    set wired_node [generateRandom 14789 $wired_nodes 0]
    set wireless_node [generateRandom 13997 3 0]
    
    if { $i % 2 == 0 } {
      $ns attach-agent $W($wired_node) $tcp($i)                ;# attach agent to node
      $ns attach-agent $node($wireless_node) $tcp_sink($i)     ;# attach sink agent to node
    } else {
       $ns attach-agent $node($wireless_node) $tcp($i)         ;# attach agent to node
       $ns attach-agent $W($wired_node) $tcp_sink($i)          ;# attach sink agent to node
    }

    $ns connect $tcp($i) $tcp_sink($i)                    ;# connect agents
    $tcp($i) set fid_ $i

    # Traffic generator
    set cbr($i) [new Application/Traffic/CBR]             ;# create traffic generator
    $cbr($i) attach-agent $tcp($i)                        ;# attach traffic generator to agent

    # # Traffic config parameters
    $cbr($i) set type_ $val(packet_type)                  ;# packet type
    $cbr($i) set packetSize_  $val(packet_size)           ;# packet size
    $cbr($i) set rate_ $val(packet_rate)                  ;# sending rate
    $cbr($i) set random_ false

    # start traffic generation
    $ns at [expr 2 + $i * 0.1] "$cbr($i) start"
    $ns at 19.5 "$cbr($i) stop"
}

# End Simulation

# Stop nodes
for {set i 0} {$i < $wireless_nodes} {incr i} {
    $ns at 20.0 "$node($i) reset"
}

$ns at 20.0 "$BS(0) reset";

# call final function
proc finish {} {
    global ns trace_file nam_file
    $ns flush-trace
    close $trace_file
    close $nam_file
}

proc halt_simulation {} {
    global ns
    puts "Simulation ending"
    $ns halt
}

$ns at 20.0001 "finish"
$ns at 20.0002 "halt_simulation"

# Run simulation
puts "Simulation starting"
$ns run

