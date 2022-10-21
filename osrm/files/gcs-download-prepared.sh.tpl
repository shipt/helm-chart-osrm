#!/usr/bin/env bash
set -euo pipefail

ensure_dependency() {
  if ! which "$1" &>/dev/null ; then
    echo "$1 not found"
    exit 1
  fi
}

ensure_dependency gsutil
ensure_dependency tar

version="{{ .Values.map.gcs.version | default "unversioned" }}"
uri="{{ .Values.map.gcs.uri }}"
file="{{ base .Values.map.gcs.uri }}"

mkdir -p "/data/maps/${version}"
cd "/data/maps/${version}"
rm -rf *
echo "Version Value: ${version}"
echo "GCS Bucket: ${uri}"
echo "Tar File Name: ${file}"

if [ ! -r downloaded.lock ]; then
  echo "Copying from GCS Bucket: ${uri}"
  gsutil -m cp "${uri}" .
  echo "Copying file: ${file}"
  tar xzvf "${file}"
  rm "${file}"

  # Rename all files so we have predictable argument name in statefulset.
  shopt -s nullglob
  for f in *.osrm*
  do
    echo "Rename $f -> map.osrm${f#*.osrm*}"
    mv "$f" "map.osrm${f#*.osrm*}"
  done

  touch downloaded.lock
  sleep 10000
fi

echo "Done!"
exit 0
