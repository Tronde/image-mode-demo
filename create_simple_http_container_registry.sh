#!/usr/bin/bash
# Description:
# - Creates a simple container registry accessible via HTTP
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
# Check for required packages
for package in ${packages[*]}; do
	if ! rpm --quiet -q ${package}; then
		sudo dnf -y install ${package}
	fi
done

# Create podman volume for the registry
podman volume create ${reg_volume_name}

# Allow insecure connections to the registry
cat << EOF > /etc/containers/registries.conf.d/002-http-registry.conf
[[registry]]
location="$(hostname -f):5000"
insecure=true
EOF

# Start the registry
podman run --name ${registry_name} \
	-p 5000:5000 \
	-v ${reg_volume_name}:/var/lib/registry:z \
	-e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true \
	-d \
	docker.io/library/registry:latest

# Configure the firewall
sudo firewall-cmd --add-port=5000/tcp --zone=internal --permanent
sudo firewall-cmd --add-port=5000/tcp --zone=public --permanent
sudo firewall-cmd --reload

echo "Verify access to registry"
echo "# curl http://$(hostname -f):5000/v2/_catalog"
echo '{"repositories":[]}'
echo ""
