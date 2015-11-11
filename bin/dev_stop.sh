#!/bin/bash

echo "Stopping Argo"
if [ -e tmp/pids/server.pid ]; then
    kill -9 $(cat tmp/pids/server.pid)
    rm tmp/pids/server.pid
    echo "Stopped Argo server"
fi
if [ -e tmp/pids/delayed_job.pid ]; then
    kill -9 $(cat tmp/pids/delayed_job.pid)
    rm tmp/pids/delayed_job.pid
    echo "Stopped delayed_job"
fi

echo "Stopping Jetty"
rake jetty:stop
