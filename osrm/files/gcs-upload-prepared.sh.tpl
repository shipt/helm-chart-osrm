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

cd "/data/maps"
if [ -d "${version}" ]; then
  echo "${version} exists, compressing and uploading to ${uri}"
  if [ -f "${file}" ] ; then
    echo "already exists"
    exit 0
  fi

  GZIP=1 tar -cvzf "${file}" -C "${version}" .
  echo "compressed ${file}"
  ls -al "${file}"
  echo "uploading to ${uri}"
  gsutil -m cp "${file}" "${uri}"
  if [ $? == 0 ]; then
    echo "complete"
  else
    echo "failure"
    exit 1
  fi
fi