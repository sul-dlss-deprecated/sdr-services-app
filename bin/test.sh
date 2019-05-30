#!/usr/bin/env bash

set -e

if [ ! -e .env ]; then
    echo ".env doesn't exist; creating it from .env_example"
    cp .env_example .env
fi

export APP_ENV='test'
export RACK_ENV='test'

bundle exec rspec
