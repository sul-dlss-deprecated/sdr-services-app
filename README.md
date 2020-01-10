# DEPRECATED

functionality has been ported to https://github.com/sul-dlss/preservation_catalog


[![Build Status](https://travis-ci.org/sul-dlss/sdr-services-app.svg)](https://travis-ci.org/sul-dlss/sdr-services-app) [![Coverage Status](https://coveralls.io/repos/sul-dlss/sdr-services-app/badge.png)](https://coveralls.io/r/sul-dlss/sdr-services-app)


# SDR Services Application

A Sinatra web application for providing access to Digital Objects in SDR Storage.

This will be replaced by preservation-catalog as a more robust, easier to maintain approach that won't have to go to the preservation storage roots for absolutely everything.

## Getting Started

- `git clone` and `cd` into the cloned repository

- setup ruby dependencies and run tests

  ```sh
  bundle install --without production
  ./bin/test.sh
  ```

## Configuration

Environment variables are set in various places, with the following order
of importance:

- On deployed apps, running under Apache/Passenger:
  - see `/etc/httpd/conf.d/z*`
  - The content of the config files is managed by puppet

- Each deployment system has configurations, and other private files, available
in the [dlss/shared_configs](https://github.com/sul-dlss/shared_configs) private repo; see
  - https://github.com/sul-dlss/shared_configs/tree/sdr-services-app_dev/config
  - https://github.com/sul-dlss/shared_configs/tree/sdr-services-app_stage/config
  - https://github.com/sul-dlss/shared_configs/tree/sdr-services-app_prod/config

- Command line values that precede `./bin/<util>`, `foreman`, or `rackup`, e.g.

  ```sh
  APP_ENV=development RACK_ENV=development .binstubs/foreman start
  APP_ENV=development RACK_ENV=development .binstubs/rackup
   ```

- `.env` file settings can supplement, without replacing, existing values
  - see `.env_example`
  - see https://github.com/bkeepers/dotenv
- `./config/boot.rb` can set defaults for missing values

## Run locally
```
bundler exec rackup
```

## Deployment

Capistrano is configured to run the deployments.  See `cap -T` for all the options.
