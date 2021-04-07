#!/bin/bash
#
# Interrogate the sys structure for device temperature
# and battery charge; log the results to stdout
#
# Temperature is in degrees Celsius
# Charge is percentage of battery remaining
# Output is optimised for Telegraf logparser
# Should work in Bash 4.3+
#
# Author: jlj@ctrl-c.club
# Suggestions and contributions welcome!
#
ver="v0.2.0"

# Set defaults
skip_batt=false
batt0=/sys/class/power_supply/BAT0
batt1=/sys/class/power_supply/BAT1
temp_dir=/sys/class/thermal/thermal_zone
temp="not set"

# Parse command-line options
while getopts 'b:hmt:v' OPTION; do
  case "$OPTION" in
    h)
      echo "$0" $ver
      echo "Interrogate the sys structure for device temperature and battery charge"
      echo "  Usage: $0 [-hmv] [-b path] [-t path]"
      echo "    -h: print this help message"
      echo "    -m: mains power; skips battery check"
      echo "    -v: print version info"
      echo "    -b PATH: full path for battery directory"
      echo "             defaults to /sys/class/power_supply/BAT[0|1]/"
      echo "    -t PATH: full path and file name for temperature"
      echo "             defaults to the highest value in /sys/class/thermal/thermal_zone[n]/temp"
      exit 0
      ;;
    m)
      skip_batt=true
      ;;
    v)
      echo "$0" $ver
      exit 0
      ;;
    b)
      batt_dir="$OPTARG"
      ;;
    t)
      temp_file="$OPTARG"
      ;;
    *)
      echo "Usage: $0 [-hmv] [-b path] [-t path]" >&2
      exit 1
      ;;
  esac
done

if [ ${skip_batt} = false ]; then
  if [ ! -d "${batt_dir}" ] || [ ! -r "${batt_dir}" ] || [ ! -x "${batt_dir}" ]; then
    # See whether we can find where battery info is stored
    if [ ! -d "${batt0}" ] && [ ! -d "${batt1}" ]; then
      echo "Usage: no battery found; -m to skip check" >&2
      exit 1
    elif [ -d "${batt0}" ]; then
      batt_dir="${batt0}"
    elif [ -d "${batt1}" ]; then
      batt_dir="${batt1}"
    fi
  fi
  # Compensate for different filenames
  batt_full_file=${batt_dir}/charge_full
  if [ ! -f "${batt_full_file}" ]; then
    batt_full_file=${batt_dir}/energy_full
    batt_curr_file=${batt_dir}/energy_now
  else
    batt_curr_file=${batt_dir}/charge_now
  fi
  # Find max and current charge values
  batt_cap=$(cat "${batt_full_file}")
  batt_curr=$(cat "${batt_curr_file}")
  # Calculate percentage and round it
  batt_perc=$(echo "${batt_curr}/${batt_cap}*100" | bc -l)
fi

# Test whether we can read the temperature file
if [ -f "${temp_file}" ] && [ -r "${temp_file}" ]; then
  # Test whether we can read an integer
  temp=$(awk '/^[0-9]+$/ { print $1 }' "$temp_file")
fi

# If an integer wasn't parsed for temp, or
#  if temp still isn't set...
if [ -z "${temp}" ] || [ "${temp}" = "not set" ]; then
  # ... See whether we can find the highest device temperature
  echo "Usage: invalid temperature file; searching defaults" >&2
  temp_file="${temp_dir}0/temp"
  if [ -f "${temp_file}" ]; then
    temp=$(cat "${temp_file}")
    i=1
    # Loop through the default file structure, until we run out of zones
    while true; do
      temp_file="${temp_dir}${i}/temp"
      if [ ! -f "${temp_file}" ]; then
        break
      fi
      temp_new=$(cat "${temp_file}")
      if [ "${temp_new}" -gt "${temp}" ]; then
        temp=${temp_new}
      fi
      i=$((i+1))
    done
  else
    echo "Usage: temperature file doesn't exist or can't be read" >&2
    exit 1
  fi
fi

# Convert and round it
temp=$(echo "${temp}/1000" | bc -l)

# Log the results to stdout
printf "%(%s)T "
printf "temp=%.0f " "$temp"
if [ ${skip_batt} = true ]; then
  printf "\n"
else
  printf "charge=%.0f\n" "$batt_perc"
fi
