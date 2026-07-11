#!/bin/bash

cd /opt/python-app

nohup python3 app.py > app.log 2>&1 &