#!/usr/bin/env bash
set -euo pipefail

ensure_dependency() {
  if ! which "$1" &>/dev/null ; then
    echo "$1 not found"
    exit 1
  fi
}

ensure_dependency osrm-extract
ensure_dependency osrm-partition
ensure_dependency osrm-customize
ensure_dependency osrm-contract
ensure_dependency sed

version="{{ .Values.map.http.version | default "unversioned" }}"
file_pbf="map.osm.pbf"
file_osrm="map.osrm"

cd "/data/maps/${version}"

sed -i "1,/weight_name.*/ s/weight_name.*/weight_name = '\$1',/" /opt/car.lua
echo "set weight_name to distance in /opt/car.lua"
cat /opt/car.lua | grep weight_name

if [ ! -r extracted.lock ]; then
  osrm-extract -p /opt/car.lua "${file_pbf}"
  #osrm-partition "${file_osrm}"
  #osrm-customize "${file_osrm}"
  osrm-contract "${file_osrm}"

  touch extracted.lock
fi

echo "Done!"
exit 0
