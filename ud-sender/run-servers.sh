#!/usr/bin/env bash
source "$(dirname $0)/../scripts/utils.sh"
source "$(dirname $0)/../scripts/mlx_env.sh"
export HRD_REGISTRY_IP="192.168.223.1"

drop_shm

num_server_threads=${THREADS:-1}
payload=${PAYLOAD:-16}

blue "Reset server QP registry"
sudo pkill memcached
memcached -l 0.0.0.0 1>/dev/null 2>/dev/null &
sleep 1

blue "Starting $num_server_threads server threads"

flags="
  --num_threads $num_server_threads \
  --dual_port 0 \
  --is_client 0 \
  --size $payload \
  --postlist 1
"

# Check for non-gdb mode
if [ "$#" -eq 0 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E \
    numactl --cpunodebind=0 --membind=0 ../build/ud-sender $flags
fi

# Check for gdb mode
if [ "$#" -eq 1 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E \
    gdb -ex run --args ../build/ud-sender $flags
fi
