#!/bin/bash

node_count=(20 40 60 80 100)
altitudes=(780 840 900 960 1020)

default_node_count=40
default_altitude=780

option=$1

ns 1805004-sat-wired.tcl $default_node_count $default_altitude $option
awk -f 1805004_parse.awk trace.tr >temp.txt

#------------------------- varying number of nodes ------------------------------#

touch res_node.txt
touch temp.txt
echo -e "\nVarying number of nodes\n" >res_node.txt

for i in "${node_count[@]}"; do
    echo -e "Number of nodes : $i\n" >>res_node.txt
    while true; do
        ns 1805004-sat-wired.tcl "$i" $default_altitude $option
        awk -f 1805004_parse.awk trace.tr >temp.txt
        if [ "$(wc -l <temp.txt)" -gt 7 ] && [ "$(grep -c "Average Delay:  0 seconds" temp.txt)" -eq 0 ]; then
            break
        fi
    done

    awk -f 1805004_parse.awk trace.tr >>res_node.txt
done

throughput=$(grep -F "Throughput:  " res_node.txt | tr -d -c [0-9."\n"])
avg_delay=$(grep -F "Average Delay:  " res_node.txt | tr -d -c [0-9."\n"])
delivery_ratio=$(grep -F "Delivery ratio:  " res_node.txt | tr -d -c [0-9."\n"])
drop_ratio=$(grep -F "Drop ratio:  " res_node.txt | tr -d -c [0-9."\n"])
python3 1805004_graph.py "${node_count[*]}" "$throughput" "Throughput(kbit/s) vs Node_Count" "throughput_node" "$option" >"${option}_node.txt"
python3 1805004_graph.py "${node_count[*]}" "$avg_delay" "Avg_delay(s) vs Node_Count" "avg_delay_node" "$option" >>"${option}_node.txt"
python3 1805004_graph.py "${node_count[*]}" "$delivery_ratio" "Delivery_ratio vs Node_Count" "delivery_ratio_node" "$option" >>"${option}_node.txt"
python3 1805004_graph.py "${node_count[*]}" "$drop_ratio" "Drop_ratio vs Node_Count" "drop_ratio_node" "$option" >>"${option}_node.txt"

#------------------------- varying altitudes------------------------------#

touch res_altitude.txt
touch temp.txt
echo -e "\nVarying altitudes\n" >res_altitude.txt

for i in "${altitudes[@]}"; do
    echo -e "Altitude : $i\n" >>res_altitude.txt
    while true; do
        ns 1805004-sat-wired.tcl $default_node_count "$i" $option
        awk -f 1805004_parse.awk trace.tr >temp.txt
        if [ "$(wc -l <temp.txt)" -gt 7 ] && [ "$(grep -c "Average Delay:  0 seconds" temp.txt)" -eq 0 ]; then
            break
        fi
    done

    awk -f 1805004_parse.awk trace.tr >>res_altitude.txt
done

throughput=$(grep -F "Throughput:  " res_altitude.txt | tr -d -c [0-9."\n"])
avg_delay=$(grep -F "Average Delay:  " res_altitude.txt | tr -d -c [0-9."\n"])
delivery_ratio=$(grep -F "Delivery ratio:  " res_altitude.txt | tr -d -c [0-9."\n"])
drop_ratio=$(grep -F "Drop ratio:  " res_altitude.txt | tr -d -c [0-9."\n"])
python3 1805004_graph.py "${altitudes[*]}" "$throughput" "Throughput(kbit/s) vs Altitude" "throughput_altitude" "$option" >"${option}_altitude.txt"
python3 1805004_graph.py "${altitudes[*]}" "$avg_delay" "Avg_delay(s) vs Altitude" "avg_delay_altitude" "$option" >>"${option}_altitude.txt"
python3 1805004_graph.py "${altitudes[*]}" "$delivery_ratio" "Delivery_ratio vs Altitude" "delivery_ratio_altitude" "$option" >>"${option}_altitude.txt"
python3 1805004_graph.py "${altitudes[*]}" "$drop_ratio" "Drop_ratio vs Altitude" "drop_ratio_altitude" "$option" >>"${option}_altitude.txt"
