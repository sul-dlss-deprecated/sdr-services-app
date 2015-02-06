#!/usr/bin/env bash

set -e

bundle config
bundle install --binstubs .binstubs --clean --jobs=3 --retry=3 --without integration staging production
bundle package --all --quiet
bundle show --paths | sort

# see commentary on this practice at
# http://blog.howareyou.com/post/66375371138/ruby-apps-best-practices

