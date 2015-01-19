#!/usr/bin/env bash

echo "Disabled until docker is evaluated"
exit 1

service="${JOB_NAME:-sdr-services-app}"
branch="${GIT_BRANCH:-master}"
dockerize boot DLSS/$service:$branch

# https://github.com/cambridge-healthcare/dockerize

# Dockerfile:
#
# FROM howareyou/ruby:1.9.3-p448
# 
# RUN rm -fr /var/apps/snomed/*
# ADD ./ /var/apps/snomed
# 
# RUN \
#   . /.profile ;\
#   rm -fr /var/apps/snomed/.git/* ;\
#   cd /var/apps/snomed && bundle install --local ;\
# # END RUN
# 
# CMD . /.profile && cd /var/apps/snomed && bin/test && foreman start
# 
# EXPOSE 3000
