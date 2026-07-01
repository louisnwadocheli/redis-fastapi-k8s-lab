#!/bin/bash

set -e

BASE_URL="http://localhost:8080/api"

echo "Testing root endpoint..."
curl -s "$BASE_URL/"
echo
echo

read -p "Enter the key: " key
read -p "Enter the value: " value

echo "Storing key-value pair..."
curl -s -X POST "$BASE_URL/cache?key=$key&value=$value"
echo
echo

echo "Retrieving value..."
curl -s "$BASE_URL/cache?key=$key"
echo
echo

echo "Test complete."