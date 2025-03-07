# Basic setup
text
network --bootproto=dhcp --device=link --activate

lang en_US.UTF-8
keyboard de
timezone CET

%pre
# In case you need to tweak your setup to get name resolution to work
# remove the comment from the following line and replace <ip-address>
# with the IP address of your podman.example.com
#echo "<ip-address> podman.example.com" >>/etc/hosts
SMALLEST_DISK=/dev/$(lsblk -d -b -o NAME,SIZE | grep -E 'sd?|vd?' | sort -k2 -n | head -n 2 | tail -n 1 | awk '{print $1}')

# Basic partitioning
cat <<EOF > /tmp/diskpart.cfg
ignoredisk --only-use=${SMALLEST_DISK}
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part / --grow --fstype xfs
EOF

# Configuring a pull secret
# Source: https://docs.fedoraproject.org/en-US/bootc/bare-metal/#_accessing_registries
mkdir -p /etc/ostree
cat <<EOF > /etc/ostree/auth.json
{
  "auths": {
    "podman.example.com:5000": {
      "auth": "cmVnaXN0cnl1c2VyOnJlZ2lzdHJ5cGFzcw=="
    }
  }
}
EOF

# Accessing insecure registry, e.g. with custom TLS certificate
mkdir -p /etc/containers/registries.conf.d/
cat <<EOF > /etc/containers/registries.conf.d/001-local-registry.conf
[[registry]]
location="podman.example.com:5000"
insecure=true
EOF
%end

%include /tmp/diskpart.cfg

# Reference the container image to install - The kickstart
# has no %packages section. A container image is being installed.
ostreecontainer --url podman.example.com:5000/rhel9.5-bootc:deploy

# Enable firewall only when firewalld is installed in bootc image
firewall --enabled --ssh --http --service=https
selinux --enforcing
skipx
syspurpose --role="Red Hat Enterprise Linux Server" --sla="Self-Support" --usage="Development/Test"

# Only inject a SSH key for root
rootpw --lock
user --name jkastnin --password changeme --plaintext --groups wheel
sshkey --username jkastnin "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwIaHUWaUCYxSb3Fxjk3SYe0V/jB5Uis+0P0AG6gWcr joerg.kastning@my-it-brain.de"
user --name ansible-user --password changeme --plaintext --groups wheel --homedir=/home/remote-ansible
sshkey --username ansible-user "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwIaHUWaUCYxSb3Fxjk3SYe0V/jB5Uis+0P0AG6gWcr joerg.kastning@my-it-brain.de"
reboot --eject
