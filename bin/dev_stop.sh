#!/bin/bash

if [ -e tmp/pids/server.pid ]; then
    kill -9 $(cat tmp/pids/server.pid)
    rm tmp/pids/server.pid
fi
if [ -e tmp/pids/delayed_job.pid ]; then
    kill -9 $(cat tmp/pids/delayed_job.pid)
    rm tmp/pids/delayed_job.pid
fi

