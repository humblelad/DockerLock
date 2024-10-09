# DockerLock
DockLock helps to created protected images, volume, networks and containers to prevent accidental deletions.

Docker by default doesn't have existing feature to prevent accidental removals. So this script creates a wrapper around docker to have this functionality.

**Usage:**
Ensure you have docker running and jq also installed. 

The protect.json containers the whitelist for volumes , containers , networks and images.

Ensure you source ~/.zshrc or ~/.bashrc after install / uninstall or the feature/ docker may break.

## Install Script
 chmod +x install.sh
./install.sh

## Uninstall Script

Run the uninstall.sh script which gets created.
