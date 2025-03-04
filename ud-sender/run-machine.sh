#!/usr/bin/env bash
source "$(dirname $0)/../scripts/utils.sh"
source "$(dirname $0)/../scripts/mlx_env.sh"
export HRD_REGISTRY_IP="192.168.223.1"

drop_shm

# lsync messes up permissions
executable="../build/ud-sender"
chmod +x $executable

num_threads=${THREADS:-1} # Threads per client machine
blue "Running $num_threads client threads"

# Check number of arguments
if [ "$#" -gt 2 ]; then
  blue "Illegal number of arguments."
  blue "Usage: ./run-machine.sh <machine_id>, or ./run-machine.sh <machine_id> gdb"
  exit
fi

if [ "$#" -eq 0 ]; then
  blue "Illegal number of arguments."
  blue "Usage: ./run-machine.sh <machine_id>, or ./run-machine.sh <machine_id> gdb"
  exit
fi

flags="\
  --num_threads $num_threads \
  --dual_port 0 \
  --is_client 1 \
  --machine_id $1
"

# Check for non-gdb mode
if [ "$#" -eq 1 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E \
    numactl --cpunodebind=0 --membind=0 $executable $flags
fi

# Check for gdb mode
if [ "$#" -eq 2 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E \
    gdb -ex run --args $executable $flags
fi
