#!/bin/sh -l

echo "Hello $1"
echo $(git version)
echo $(gh --version)
time=$(date)
echo "::set-output name=time::$time"
