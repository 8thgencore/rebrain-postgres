#!/bin/bash

ETCD_VER=v3.5.18

# Choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

# Remove old files and create necessary directories
rm -f /task/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /task/etcd/ && mkdir -p /task/etcd/

# Print the URL to verify it
echo "Downloading from: ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz"

# Download the tarball
curl -L "${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz" -o /task/etcd-${ETCD_VER}-linux-amd64.tar.gz

# Check if the download was successful
if [ ! -f /task/etcd-${ETCD_VER}-linux-amd64.tar.gz ]; then
  echo "Download failed. Please check the URL and try again."
  exit 1
fi

# Extract the tarball
tar xzvf /task/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /task/etcd --strip-components=1

# Clean up the tarball
rm -f /task/etcd-${ETCD_VER}-linux-amd64.tar.gz

# Verify the installation
/task/etcd/etcd --version
/task/etcd/etcdctl version
