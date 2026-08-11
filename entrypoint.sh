#!/bin/sh
set -e

exec /bin/bash -c "/run.sh ${SENTINEL_HOST} ${SENTINEL_PORT}"
