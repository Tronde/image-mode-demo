#!/usr/bin/bash
# Description:
# - Creates a simple container registry
#		- With login credentials
#		- With TLS key pair
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

cat <<EOF >/tmp/req.cnf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = DE
ST = NRW
L = Augustdorf
O = Red Hat Demo
OU = TAM Services
CN = ${HOSTNAME}

[v3_req]
keyUsage = critical, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:${HOSTNAME}
EOF

## Main
# Check for required packages
for package in ${packages[*]}; do
	if ! rpm --quiet -q ${package}; then
		dnf -y install ${package}
	fi
done

# Create foldes for the registry
mkdir -p ${reg_base_dir}/{${reg_auth_dir},${reg_certs_dir},${reg_data_dir}}

# Generate credentials for accessing the registry
htpasswd -bBc ${reg_base_dir}/${reg_auth_dir}/htpasswd \
	${registry_user} \
	${registry_pass}

# Generate the TLS key pair
openssl req -newkey rsa:4096 -nodes -sha256 \
	-keyout ${reg_base_dir}/${reg_certs_dir}/${cert_domain}.key -x509 -days 365 \
	-out ${reg_base_dir}/${reg_certs_dir}/${cert_domain}.crt \
	-config /tmp/req.cnf

if ! [ -f /etc/pki/ca-trust/source/anchors/${cert_domain}.crt ]; then
	cp ${reg_base_dir}/${reg_certs_dir}/${cert_domain}.crt /etc/pki/ca-trust/source/anchors/
	update-ca-trust
fi

# Start the registry
podman run --name ${registry_name} \
	-p 5000:5000 \
	-v ${reg_base_dir}/${reg_data_dir}:/var/lib/registry:z \
	-v ${reg_base_dir}/${reg_auth_dir}:/auth:z \
	-e "REGISTRY_AUTH=htpasswd" \
	-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
	-e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
	-v ${reg_base_dir}/${reg_certs_dir}:/certs:z \
	-e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/${cert_domain}.crt" \
	-e "REGISTRY_HTTP_TLS_KEY=/certs/${cert_domain}.key" \
	-e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true \
	-d \
	docker.io/library/registry:latest

# Configure the firewall
firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public --permanent
firewall-cmd --reload

# Print verify info ot STDOUT
echo "Check whether ${HOSTNAME} is in trust list"
trust list | grep -i ${HOSTNAME}
echo "Verify access to registry"
echo "# curl -k https://${HOSTNAME}:5000/v2/_catalog"
echo '{"repositories":[]}'
echo ""
echo "# openssl s_client -connect ${HOSTNAME}:5000 -servername ${HOSTNAME}"
