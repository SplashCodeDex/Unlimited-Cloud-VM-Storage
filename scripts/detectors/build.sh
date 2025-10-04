#!/bin/bash

if [ -f "$1/build.gradle" ] || [ -f "$1/pom.xml" ] || [ -f "$1/CMakeLists.txt" ]; then
    echo "build"
fi
