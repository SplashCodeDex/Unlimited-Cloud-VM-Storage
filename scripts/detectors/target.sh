#!/bin/bash

if [ -f "$1/Cargo.toml" ] || [ -f "$1/pom.xml" ]; then
    echo "target"
fi
