#!/bin/bash

node_count=(20 40 63 80 102)
flow_count=(10 19 31 40 52)
pkt_rates=(100 210 301 400 500)

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

#------------------------- comparison graph varying number of flows ------------------------------#

existing=$(cat "1_flow.txt")
modified=$(cat "2_flow.txt")
existing2=$(cat "3_flow.txt")

comparison_flows() {
    res1=$(echo "$existing" | head -"$1" | tail -1)
    res2=$(echo "$modified" | head -"$1" | tail -1)
    res3=$(echo "$existing2" | head -"$1" | tail -1)
    python3 1805004_compare_graph.py "${flow_count[*]}" "$res1" "$res2" "$res3" "$2" "$3" "$4" "$5"
}

counter=2
comparison_flows $counter "Throughput(kbit/s) vs Flow_Count" "throughput_flow" "Throughput_diff(%) vs Flow_Count" "throughput_diff_flow"

counter=$((counter + 2))
comparison_flows $counter "Avg_delay(s) vs Flow_Count" "avg_delay_flow" "Avg_delay_diff(%) vs Flow_Count" "avg_delay_diff_flow"

counter=$((counter + 2))
comparison_flows $counter "Delivery_ratio(%) vs Flow_Count" "delivery_ratio_flow" "Delivery_ratio_diff(%) vs Flow_Count" "delivery_ratio_diff_flow"

counter=$((counter + 2))
comparison_flows $counter "Drop_ratio(%) vs Flow_Count" "drop_ratio_flow" "Drop_ratio_diff(%) vs Flow_Count" "drop_ratio_diff_flow"

#------------------------- comparison graph varying packet rate ------------------------------#

existing=$(cat "1_pkt_rate.txt")
modified=$(cat "2_pkt_rate.txt")
existing2=$(cat "3_pkt_rate.txt")

comparison_pkt_rate() {
    res1=$(echo "$existing" | head -"$1" | tail -1)
    res2=$(echo "$modified" | head -"$1" | tail -1)
    res3=$(echo "$existing2" | head -"$1" | tail -1)
    python3 1805004_compare_graph.py "${pkt_rates[*]}" "$res1" "$res2" "$res3" "$2" "$3" "$4" "$5"
}

counter=2
comparison_pkt_rate $counter "Throughput(kbit/s) vs Pkt_Rate" "throughput_pkt_rate" "Throughput_diff(%) vs Pkt_Rate" "throughput_diff_pkt_rate"

counter=$((counter + 2))
comparison_pkt_rate $counter "Avg_delay(s) vs Pkt_Rate" "avg_delay_pkt_rate" "Avg_delay_diff(%) vs Pkt_Rate" "avg_delay_diff_pkt_rate"

counter=$((counter + 2))
comparison_pkt_rate $counter "Delivery_ratio(%) vs Pkt_Rate" "delivery_ratio_pkt_rate" "Delivery_ratio_diff(%) vs Pkt_Rate" "delivery_ratio_diff_pkt_rate"

counter=$((counter + 2))
comparison_pkt_rate $counter "Drop_ratio(%) vs Pkt_Rate" "drop_ratio_pkt_rate" "Drop_ratio_diff(%) vs Pkt_Rate" "drop_ratio_diff_pkt_rate"
