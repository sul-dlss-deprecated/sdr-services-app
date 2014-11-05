#!/usr/bin/env bash

set -e

export APP_ENV='test'
export RACK_ENV='test'

.binstubs/rspec
.binstubs/cucumber --strict
