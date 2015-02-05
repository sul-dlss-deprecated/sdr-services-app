#!/usr/bin/env bash

set -e

bundle install --binstubs .binstubs --jobs=3 --retry=3
bundle package --all --quiet

# see commentary on this practice at
# http://blog.howareyou.com/post/66375371138/ruby-apps-best-practices

