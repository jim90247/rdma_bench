#!/usr/bin/env bash
source "$(dirname $0)/../scripts/utils.sh"
source "$(dirname $0)/../scripts/mlx_env.sh"
export HRD_REGISTRY_IP="192.168.223.1"

drop_shm
exe="../build/rw-tput-receiver"
chmod +x $exe

num_threads=${THREADS:-1} # Threads per client machine
uc=${uc:-0}
payload=${PAYLOAD:-16}
blue "Running $num_threads client threads. uc=${uc}"

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
  --use_uc ${uc} \
  --is_client 1 \
  --machine_id $1 \
  --size $payload \
  --postlist 1 \
  --do_read 1
"

# Check for non-gdb mode
if [ "$#" -eq 1 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E numactl --cpunodebind=0 --membind=0 $exe $flags
fi

# Check for gdb mode
if [ "$#" -eq 2 ]; then
  sudo LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-"$HOME/.local/lib"}" -E gdb -ex run --args $exe $flags
fi
