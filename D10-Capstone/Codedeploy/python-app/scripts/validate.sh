#!/bin/bash

sleep 10

curl http://localhost:5000

if [ $? -eq 0 ]
then
    echo "Application Running"
    exit 0
else
    echo "Application Failed"
    exit 1
fi