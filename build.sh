#!/bin/bash
# Script to download Joplin source and build the joplin docker image

source .env

# Check JOPLIN_TAG is defined
if [ -z "${JOPLIN_TAG}" ]; then
  echo "Error : JOPLIN_TAG variable is not defined in .env file"
  exit 1
fi

# Download the archive from GitHub
ARCHIVE="joplin-${JOPLIN_TAG}.tar.gz"
URL="https://github.com/laurent22/joplin/archive/refs/tags/v${JOPLIN_TAG}.tar.gz"

echo "Downloading $URL..."
if ! curl -fL -o "$ARCHIVE" "$URL"; then
  echo "Error: Failed to download $URL"
  exit 1
fi

# Create the extraction directory
mkdir "joplin-${JOPLIN_TAG}"

# Extract the archive into the directory
tar zxvf "$ARCHIVE" -C "joplin-${JOPLIN_TAG}/"

# Change to the extracted source directory
cd "joplin-${JOPLIN_TAG}/joplin-${JOPLIN_TAG}" || exit 1

# Build the Docker image
docker build -t "d4void/joplin:${JOPLIN_TAG}" -f Dockerfile.server .

# Push the Docker image to Docker Hub
docker push "d4void/joplin:${JOPLIN_TAG}"

# Cleaning
rm -f "$ARCHIVE"
rm -rf "joplin-${JOPLIN_TAG}"
