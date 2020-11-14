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

# Find where battery info is stored
bat_dir="/sys/class/power_supply/BAT0"
if [ ! -d ${bat_dir} ]; then
  bat_dir="/sys/class/power_supply/BAT1"
  if [ ! -d ${bat_dir} ]; then
    echo "Usage: no BAT# found; not laptop?" 1>&2
    exit 1
  fi
fi

# Compensate for different filenames
bat_full_file=${bat_dir}/charge_full
if [ ! -f ${bat_full_file} ]; then
  bat_full_file=${bat_dir}/energy_full
  bat_curr_file=${bat_dir}/energy_now
else
  bat_curr_file=${bat_dir}/charge_now
fi

# Find max and current charge values
bat_cap=`cat ${bat_full_file}`
bat_curr=`cat ${bat_curr_file}`

# Calculate percentage and round it
bat_perc=`echo "${bat_curr}/${bat_cap}*100" | bc -l`

# Find device temperature
temp=`cat /sys/class/thermal/thermal_zone0/temp`
if [ -d /sys/class/thermal/thermal_zone1 ]; then
  temp1=`cat /sys/class/thermal/thermal_zone1/temp`
  if [ ${temp1} -gt ${temp} ]; then
    temp=$temp1
  fi
fi

# Convert and round it
temp=`echo "${temp}/1000" | bc -l`

# Log the results to stdout
printf "%(%s)T "
printf "temp=%.0f " $temp
printf "charge=%.0f\n" $bat_perc
