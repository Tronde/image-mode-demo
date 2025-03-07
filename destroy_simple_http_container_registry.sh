#!/usr/bin/bash
# Description:
# - Destroys the simple container registry created by
#   create_simple_container_registry.sh
# - Source:  How to implement a simple personal/private Linux container image registry for internal use
#	- URL: https://www.redhat.com/en/blog/simple-container-registry
#	- This script only needs to run once to create and setup the registy
#		After creation it can be controled using well known podman commands
#
## Script options

set -e					# Exit immediatley if any command has a non-zero exit status
# set -x				# Enable debugging mode
set -u					# Fail when referencing a variable that has not been defined
set -o pipefail	# Fail if any command in a pipeline fails

## Source registry variables
source registry.vars

## Main
podman stop ${registry_name}
podman rm ${registry_name}
podman rmi registry:latest
podman volume rm ${reg_volume_name}
rm /etc/containers/registries.conf.d/002-http-registry.conf

# Configure the firewall
firewall-cmd --remove-port=5000/tcp --zone=internal --permanent
firewall-cmd --remove-port=5000/tcp --zone=public --permanent
firewall-cmd --reload
