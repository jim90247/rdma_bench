#!/usr/bin/env bash
source "$(dirname $0)/../scripts/utils.sh"
source "$(dirname $0)/../scripts/mlx_env.sh"
export HRD_REGISTRY_IP="192.168.223.1"

drop_shm
exe="../build/rw-tput-receiver"
chmod +x $exe

num_server_threads=${THREADS:-1}
uc=${uc:-0}

blue "Reset server QP registry"
sudo pkill memcached

# Spawn memcached, but wait for it to start
memcached -l 0.0.0.0 1>/dev/null 2>/dev/null &
while ! nc -z localhost 11211; do sleep .1; done
echo "Server: memcached server is open for business on port 11211"

blue "Starting $num_server_threads server threads"

flags="
  --num_threads $num_server_threads \
  --dual_port 0 \
  --use_uc ${uc} \
  --is_client 0
"

# Check for non-gdb mode
if [ "$#" -eq 0 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E numactl --cpunodebind=0 --membind=0 $exe $flags
fi

# Check for gdb mode
if [ "$#" -eq 1 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E gdb -ex run --args $exe $flags
fi
