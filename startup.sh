#!/bin/bash

echo "=== Starting Robot System ==="

echo "Cleaning up old processes..."
pkill -9 -f zenoh
pkill -9 -f rviz2
sleep 2

echo "Starting Zenoh bridge..."
zenoh-bridge-ros2dds -e tcp/10.8.250.18:7447 > /tmp/zenoh.log 2>&1 &
ZENOH_PID=$!

sleep 3

# Verify Zenoh is running
if ! kill -0 $ZENOH_PID 2>/dev/null; then
    echo "ERROR: Zenoh bridge failed to start!"
    cat /tmp/zenoh.log
    exit 1
fi

echo "Zenoh bridge started (PID: $ZENOH_PID)"
rviz2 -d default.rviz

trap 'echo "Shutting down..."; kill $ZENOH_PID; exit 0' SIGINT SIGTERM SIGSEGV