#!/bin/bash

# show main processes
echo "show container processes"
ps -eaf | head -1
ps -eaf | grep -v '00 grep'
