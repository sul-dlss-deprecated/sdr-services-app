[![Build Status](https://travis-ci.org/sul-dlss/sdr-services-app.svg)](https://travis-ci.org/sul-dlss/sdr-services-app) [![Coverage Status](https://coveralls.io/repos/sul-dlss/sdr-services-app/badge.png)](https://coveralls.io/r/sul-dlss/sdr-services-app) [![Dependency Status](https://gemnasium.com/sul-dlss/sdr-services-app.svg)](https://gemnasium.com/sul-dlss/sdr-services-app)


# SDR Services Application

A web application for providing access to Digital Objects in SDR Storage.

## Requirements

- database service options
  + mysql - test, local, development
  + oracle - integration, staging, production

## Getting Started
  ```sh
  ./bin/setup.sh
  ./bin/test.sh
  ```

## Configuration

Environment variables are set in various places, with the following order
of importance:

- On deployed apps, running under Apache/Passenger:
  - see `/etc/httpd/conf.d/z*`
  - The content of the config files is managed by puppet
- Command line values that precede `./bin/<util>`, `foreman`, or `rackup`, e.g.

  ```sh
  APP_ENV=local RACK_ENV=development .binstubs/foreman start
  APP_ENV=local RACK_ENV=development .binstubs/rackup
  ```

- `.env` file settings can supplement, without replacing, existing values
  - see `.env_example`
  - see https://github.com/bkeepers/dotenv
- `./config/boot.rb` can set defaults for missing values

## Deployment

Capistrano is configured to run all the deployments.  See `cap -T` for all the options.  The target system configurations, and other private configuration files, are available in the private repo at https://github.com/sul-dlss/sdr-configs
