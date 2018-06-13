#!/usr/bin/env bash

set -e

if [ ! -e .env ]; then
    echo ".env doesn't exist; creating it from .env_example"
    cp .env_example .env
fi

if [ ! -e ./config/database.yml ]; then
    echo "config/database.yml doesn't exist; creating it from config/database_example.yml"
    cp config/database_example.yml config/database.yml
fi

export APP_ENV='test'
export RACK_ENV='test'

bundle exec rspec
bundle exec cucumber --strict
