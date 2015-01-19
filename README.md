A web application for providing access to Digital Objects in SDR Storage

Getting Started
./bin/setup.sh
./bin/test.sh

Environment variables are set in various places, with the following order
of importance:
- On deployed apps, running under Apache/Passenger, see /etc/httpd/conf.d/z*
  - The content of the config files is managed by puppet
- Command line values that precede ./bin/<util>, foreman, or rackup, e.g.
  - APP_ENV=local RACK_ENV=development .binstubs/foreman start
  - APP_ENV=local RACK_ENV=development .binstubs/rackup
  - This is used in ./bin/test.sh
- .env file can supplement, without replacing existing values
- ./config/boot.rb can set defaults for missing values

