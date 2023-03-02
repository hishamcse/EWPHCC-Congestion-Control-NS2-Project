#!/bin/bash

node_count=(20 40 60 80 100)
altitudes=(780 840 900 960 1020)

#------------------------- comparison graph varying number of nodes ------------------------------#

existing=$(cat "1_node.txt")
modified=$(cat "2_node.txt")
existing2=$(cat "3_node.txt")

comparison_nodes() {
    res1=$(echo "$existing" | head -"$1" | tail -1)
    res2=$(echo "$modified" | head -"$1" | tail -1)
    res3=$(echo "$existing2" | head -"$1" | tail -1)
    python3 1805004_compare_graph.py "${node_count[*]}" "$res1" "$res2" "$res3" "$2" "$3" "$4" "$5"
}

counter=2
comparison_nodes $counter "Throughput(kbit/s) vs Node_Count" "throughput_node" "Throughput_diff(%) vs Node_Count" "throughput_diff_node"

counter=$((counter + 2))
comparison_nodes $counter "Avg_delay(s) vs Node_Count" "avg_delay_node" "Avg_delay_diff(%) vs Node_Count" "avg_delay_diff_node"

counter=$((counter + 2))
comparison_nodes $counter "Delivery_ratio(%) vs Node_Count" "delivery_ratio_node" "Delivery_ratio_diff(%) vs Node_Count" "delivery_ratio_diff_node"

counter=$((counter + 2))
comparison_nodes $counter "Drop_ratio(%) vs Node_Count" "drop_ratio_node" "Drop_ratio_diff(%) vs Node_Count" "drop_ratio_diff_node"

#------------------------- comparison graph varying altitudes ------------------------------#

existing=$(cat "1_altitude.txt")
modified=$(cat "2_altitude.txt")
existing2=$(cat "3_altitude.txt")

comparison_altitudes() {
    res1=$(echo "$existing" | head -"$1" | tail -1)
    res2=$(echo "$modified" | head -"$1" | tail -1)
    res3=$(echo "$existing2" | head -"$1" | tail -1)
    python3 1805004_compare_graph.py "${altitudes[*]}" "$res1" "$res2" "$res3" "$2" "$3" "$4" "$5"
}

counter=2
comparison_altitudes $counter "Throughput(kbit/s) vs Altitude" "throughput_altitude" "Throughput_diff(%) vs Altitude" "throughput_diff_altitude"

counter=$((counter + 2))
comparison_altitudes $counter "Avg_delay(s) vs Altitude" "avg_delay_altitude" "Avg_delay_diff(%) vs Altitude" "avg_delay_diff_altitude"

counter=$((counter + 2))
comparison_altitudes $counter "Delivery_ratio(%) vs Altitude" "delivery_ratio_altitude" "Delivery_ratio_diff(%) vs Altitude" "delivery_ratio_diff_altitude"

counter=$((counter + 2))
comparison_altitudes $counter "Drop_ratio(%) vs Altitude" "drop_ratio_altitude" "Drop_ratio_diff(%) vs Altitude" "drop_ratio_diff_altitude"
