# Basic setup
text
network --bootproto=dhcp --device=link --activate

lang en_US.UTF-8
keyboard de
timezone CET

%pre
SMALLEST_DISK=$(lsblk -d -b -o NAME,SIZE | sort -k2 -n | head -n 2 | tail -n 1 | awk '{print $1}')

# Basic partitioning
cat <<EOF > /tmp/diskpart.cfg
ignoredisk --only-use=${SMALLEST_DISK}
clearpart --all --initlabel --disklabel=gpt
repart --add-boot
part / --grow --fstype xfs
EOF

# Configuring a pull secret
# Source: https://docs.fedoraproject.org/en-US/bootc/bare-metal/#_accessing_registries
mkdir -p /etc/ostree
cat <<EOF > /etc/ostree/json
{
  "auths": {
    "t14-podman-1:5000": {
      "auth": "cmVnaXN0cnl1c2VyOnJlZ2lzdHJ5cGFzcw=="
    }
  }
}
EOF

# Accessing insecure registry, e.g. with custom TLS certificate
mkdir -p /etc/containers/registries.conf.d/
cat <<EOF > /etc/containers/registries.conf.d/001-local-registry.conf
[[registry]]
location="t14-podman-1:5000"
insecure=true
EOF
%end

# Reference the container image to install - The kickstart
# has no %packages section. A container image is being installed.
ostreecontainer --url registry.redhat.io/rhel9/rhel-bootc:9.4

firewall --enabled --ssh
services --enabled=sshd
selinux --enforcing
skipx
syspurpose --role="Red Hat Enterprise Linux Server" --sla="Self-Support" --usage="Development/Test"

# Only inject a SSH key for root
rootpw --lock
user --name jkastnin --password redhat123 --plaintext --groups wheel
sshkey --username jkastnin "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwIaHUWaUCYxSb3Fxjk3SYe0V/jB5Uis+0P0AG6gWcr joerg.kastning@my-it-brain.de"
user --name ansible-user --password redhat123 --plaintext --groups wheel --homedir=/home/remote-ansible
sshkey --username ansible-user "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwIaHUWaUCYxSb3Fxjk3SYe0V/jB5Uis+0P0AG6gWcr joerg.kastning@my-it-brain.de"
reboot --eject
