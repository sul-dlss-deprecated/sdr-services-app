#!/usr/bin/env bash


# http://ddollar.github.io/foreman/
# foreman is configured by .env and Procfile 
# .env is not in git repo, it should contain:
#RACK_ENV="${RACK_ENV:-development}"
#PORT="${PORT:-3000}"
.binstubs/foreman start

# see also:
#foreman export # for bluepill, initab, launchd, upstart etc.
#foreman run ./bin/console

