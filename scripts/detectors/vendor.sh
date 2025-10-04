#!/bin/bash

if [ -f "$1/Gemfile" ] || [ -f "$1/go.mod" ] || [ -f "$1/composer.json" ]; then
    echo "vendor"
fi
