#!/bin/bash

node_count=(20 40 60 80 100)
flow_count=(10 20 30 40 50)
pkt_rates=(100 200 300 400 500)
node_speeds=(5 10 16 20 25)

default_node_count=40
default_flow_count=20
default_pkt_rate=300
default_speed=5

option=$1

# ns 1805004_main.tcl $default_node_count $default_flow_count $default_pkt_rate $default_speed $option
# awk -f 1805004_parse.awk trace.tr >temp.txt

# #------------------------- varying number of nodes ------------------------------#

# default_pkt_rate=200
# touch res_node.txt
# touch temp.txt
# echo -e "\nVarying number of nodes\n" >res_node.txt

# for i in "${node_count[@]}"; do
#     echo -e "Number of nodes : $i\n" >>res_node.txt
#     while true; do
#         ns 1805004_main.tcl "$i" $default_flow_count $default_pkt_rate $default_speed $option
#         awk -f 1805004_parse.awk trace.tr >temp.txt
#         if [ "$(wc -l <temp.txt)" -gt 7 ] && [ "$(grep -c "Average Delay:  0 seconds" temp.txt)" -eq 0 ]; then
#             break
#         fi
#     done

#     awk -f 1805004_parse.awk trace.tr >>res_node.txt
# done

# throughput=$(grep -F "Throughput:  " res_node.txt | tr -d -c [0-9."\n"])
# avg_delay=$(grep -F "Average Delay:  " res_node.txt | tr -d -c [0-9."\n"])
# delivery_ratio=$(grep -F "Delivery ratio:  " res_node.txt | tr -d -c [0-9."\n"])
# drop_ratio=$(grep -F "Drop ratio:  " res_node.txt | tr -d -c [0-9."\n"])
# energy_per_pkt=$(grep -F "Energy consumption per packet:  " res_node.txt | tr -d -c [0-9."\n"])
# energy_per_byte=$(grep -F "Energy consumption per byte:  " res_node.txt | tr -d -c [0-9."\n"])
# python3 1805004_graph.py "${node_count[*]}" "$throughput" "Throughput(kbit/s) vs Node_Count" "throughput_node" "$option" >"${option}_node.txt"
# python3 1805004_graph.py "${node_count[*]}" "$avg_delay" "Avg_delay(s) vs Node_Count" "avg_delay_node" "$option" >>"${option}_node.txt"
# python3 1805004_graph.py "${node_count[*]}" "$delivery_ratio" "Delivery_ratio vs Node_Count" "delivery_ratio_node" "$option" >>"${option}_node.txt"
# python3 1805004_graph.py "${node_count[*]}" "$drop_ratio" "Drop_ratio vs Node_Count" "drop_ratio_node" "$option" >>"${option}_node.txt"
# python3 1805004_graph.py "${node_count[*]}" "$energy_per_pkt" "Energy_per_pkt vs Node_Count" "energy_per_pkt_node" "$option" >>"${option}_node.txt"
# python3 1805004_graph.py "${node_count[*]}" "$energy_per_byte" "Energy_per_byte vs Node_Count" "energy_per_byte_node" "$option" >>"${option}_node.txt"

# #------------------------- varying number of flows ------------------------------#

# default_pkt_rate=300
# touch res_flow.txt
# touch temp.txt
# echo -e "\nVarying number of flows\n" >res_flow.txt

# for i in "${flow_count[@]}"; do
#     echo -e "Number of flows : $i\n" >>res_flow.txt
#     while true; do
#         ns 1805004_main.tcl $default_node_count "$i" $default_pkt_rate $default_speed $option
#         awk -f 1805004_parse.awk trace.tr >temp.txt
#         if [ "$(wc -l <temp.txt)" -gt 7 ] && [ "$(grep -c "Average Delay:  0 seconds" temp.txt)" -eq 0 ]; then
#             break
#         fi
#     done

#     awk -f 1805004_parse.awk trace.tr >>res_flow.txt
# done

# throughput=$(grep -F "Throughput:  " res_flow.txt | tr -d -c [0-9."\n"])
# avg_delay=$(grep -F "Average Delay:  " res_flow.txt | tr -d -c [0-9."\n"])
# delivery_ratio=$(grep -F "Delivery ratio:  " res_flow.txt | tr -d -c [0-9."\n"])
# drop_ratio=$(grep -F "Drop ratio:  " res_flow.txt | tr -d -c [0-9."\n"])
# energy_per_pkt=$(grep -F "Energy consumption per packet:  " res_flow.txt | tr -d -c [0-9."\n"])
# energy_per_byte=$(grep -F "Energy consumption per byte:  " res_flow.txt | tr -d -c [0-9."\n"])
# python3 1805004_graph.py "${flow_count[*]}" "$throughput" "Throughput(kbit/s) vs flow_count" "throughput_flow" "$option" >"${option}_flow.txt"
# python3 1805004_graph.py "${flow_count[*]}" "$avg_delay" "Avg_delay(s) vs flow_count" "avg_delay_flow" "$option" >>"${option}_flow.txt"
# python3 1805004_graph.py "${flow_count[*]}" "$delivery_ratio" "Delivery_ratio vs flow_count" "delivery_ratio_flow" "$option" >>"${option}_flow.txt"
# python3 1805004_graph.py "${flow_count[*]}" "$drop_ratio" "Drop_ratio vs flow_count" "drop_ratio_flow" "$option" >>"${option}_flow.txt"
# python3 1805004_graph.py "${flow_count[*]}" "$energy_per_pkt" "Energy_per_pkt vs flow_count" "energy_per_pkt_flow" "$option" >>"${option}_flow.txt"
# python3 1805004_graph.py "${flow_count[*]}" "$energy_per_byte" "Energy_per_byte vs flow_count" "energy_per_byte_flow" "$option" >>"${option}_flow.txt"

# #------------------------- varying packet rate ------------------------------#

# touch res_pkt_rate.txt
# touch temp.txt
# echo -e "\nVarying packet rate\n" >res_pkt_rate.txt

# for i in "${pkt_rates[@]}"; do
#     echo -e "Packet rate : $i\n" >>res_pkt_rate.txt
#     while true; do
#         ns 1805004_main.tcl $default_node_count $default_flow_count "$i" $default_speed $option
#         awk -f 1805004_parse.awk trace.tr >temp.txt
#         if [ "$(wc -l <temp.txt)" -gt 7 ] && [ "$(grep -c "Average Delay:  0 seconds" temp.txt)" -eq 0 ]; then
#             break
#         fi
#     done

#     awk -f 1805004_parse.awk trace.tr >>res_pkt_rate.txt
# done

# throughput=$(grep -F "Throughput:  " res_pkt_rate.txt | tr -d -c [0-9."\n"])
# avg_delay=$(grep -F "Average Delay:  " res_pkt_rate.txt | tr -d -c [0-9."\n"])
# delivery_ratio=$(grep -F "Delivery ratio:  " res_pkt_rate.txt | tr -d -c [0-9."\n"])
# drop_ratio=$(grep -F "Drop ratio:  " res_pkt_rate.txt | tr -d -c [0-9."\n"])
# energy_per_pkt=$(grep -F "Energy consumption per packet:  " res_pkt_rate.txt | tr -d -c [0-9."\n"])
# energy_per_byte=$(grep -F "Energy consumption per byte:  " res_pkt_rate.txt | tr -d -c [0-9."\n"])
# python3 1805004_graph.py "${pkt_rates[*]}" "$throughput" "Throughput(kbit/s) vs pkt_rate" "throughput_pkt_rate" "$option" >"${option}_pkt_rate.txt"
# python3 1805004_graph.py "${pkt_rates[*]}" "$avg_delay" "Avg_delay(s) vs pkt_rate" "avg_delay_pkt_rate" "$option" >>"${option}_pkt_rate.txt"
# python3 1805004_graph.py "${pkt_rates[*]}" "$delivery_ratio" "Delivery_ratio vs pkt_rate" "delivery_ratio_pkt_rate" "$option" >>"${option}_pkt_rate.txt"
# python3 1805004_graph.py "${pkt_rates[*]}" "$drop_ratio" "Drop_ratio vs pkt_rate" "drop_ratio_pkt_rate" "$option" >>"${option}_pkt_rate.txt"
# python3 1805004_graph.py "${pkt_rates[*]}" "$energy_per_pkt" "Energy_per_pkt vs pkt_rate" "energy_per_pkt_pkt_rate" "$option" >>"${option}_pkt_rate.txt"
# python3 1805004_graph.py "${pkt_rates[*]}" "$energy_per_byte" "Energy_per_byte vs pkt_rate" "energy_per_byte_pkt_rate" "$option" >>"${option}_pkt_rate.txt"

#------------------------- varying speed ------------------------------#

touch res_speed.txt
touch temp.txt
echo -e "\nVarying speed\n" >res_speed.txt

for i in "${node_speeds[@]}"; do
    echo -e "Speed : $i\n" >>res_speed.txt
    while true; do
        ns 1805004_main.tcl $default_node_count $default_flow_count $default_pkt_rate "$i" $option
        awk -f 1805004_parse.awk trace.tr >temp.txt
        if [ "$(wc -l <temp.txt)" -gt 7 ] && [ "$(grep -c "Average Delay:  0 seconds" temp.txt)" -eq 0 ]; then
            break
        fi
    done

    awk -f 1805004_parse.awk trace.tr >>res_speed.txt
done

throughput=$(grep -F "Throughput:  " res_speed.txt | tr -d -c [0-9."\n"])
avg_delay=$(grep -F "Average Delay:  " res_speed.txt | tr -d -c [0-9."\n"])
delivery_ratio=$(grep -F "Delivery ratio:  " res_speed.txt | tr -d -c [0-9."\n"])
drop_ratio=$(grep -F "Drop ratio:  " res_speed.txt | tr -d -c [0-9."\n"])
energy_per_pkt=$(grep -F "Energy consumption per packet:  " res_speed.txt | tr -d -c [0-9."\n"])
energy_per_byte=$(grep -F "Energy consumption per byte:  " res_speed.txt | tr -d -c [0-9."\n"])
python3 1805004_graph.py "${node_speeds[*]}" "$throughput" "Throughput(kbit/s) vs speed" "throughput_speed" "$option" >"${option}_speed.txt"
python3 1805004_graph.py "${node_speeds[*]}" "$avg_delay" "Avg_delay(s) vs speed" "avg_delay_speed" "$option" >>"${option}_speed.txt"
python3 1805004_graph.py "${node_speeds[*]}" "$delivery_ratio" "Delivery_ratio vs speed" "delivery_ratio_speed" "$option" >>"${option}_speed.txt"
python3 1805004_graph.py "${node_speeds[*]}" "$drop_ratio" "Drop_ratio vs speed" "drop_ratio_speed" "$option" >>"${option}_speed.txt"
python3 1805004_graph.py "${node_speeds[*]}" "$energy_per_pkt" "Energy_per_pkt vs speed" "energy_per_pkt_speed" "$option" >>"${option}_speed.txt"
python3 1805004_graph.py "${node_speeds[*]}" "$energy_per_byte" "Energy_per_byte vs speed" "energy_per_byte_speed" "$option" >>"${option}_speed.txt"
