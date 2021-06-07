#!/bin/bash
set -xe

server_ip=${SERVER_IP:-"192.168.10.208"}
server_ports=${SERVER_PORTS:-1}
server_threads=${SERVER_THREADS:-2}

num_client_nodes=${CLIENTS:-1}
client_ports=${CLIENT_PORTS:-1}
client_threads=${CLIENT_THREADS:-12}

total_client_threads=$((num_client_nodes * client_threads))
# postlist = min(32, total_client_threads)
postlist=${POSTLIST:-$((total_client_threads > 32 ? 32 : total_client_threads))}
scripts=(run-machine.sh run-servers.sh)

sed -i -E "s/HRD_REGISTRY_IP=.*/HRD_REGISTRY_IP=\"${server_ip}\"/g" "${scripts[@]}"
sed -i -E "s/--num-server-ports [0-9]+/--num-server-ports ${server_ports}/g" "${scripts[@]}"
sed -i -E "s/--num-client-ports [0-9]+/--num-client-ports ${client_ports}/g" "${scripts[@]}"
sed -i -E "s/num_threads=[0-9]+/num_threads=${client_threads}/g" run-machine.sh
sed -i -E "s/--postlist [0-9]+/--postlist ${postlist}/g" run-servers.sh
sed -i -E "s/server_threads=[0-9]+/server_threads=${server_threads}/g" run-servers.sh
sed -i -E "s/#define NUM_WORKERS [0-9]+/#define NUM_WORKERS ${server_threads}/g" main.h
sed -i -E "s/#define NUM_CLIENTS [0-9]+/#define NUM_CLIENTS ${total_client_threads}/g" main.h
