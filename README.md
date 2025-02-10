# RHEL image mode demo

This repository contains scripts and files I use as supplementary material for my demos and workshops on [RHEL image mode](https://developers.redhat.com/products/rhel-image-mode/overview). It is referenced by some introduction and tutorial I'm currently working on.

Feel free to use the content of this repo at your own risk for your own purposes. Only do me the favor and don't run the simple registry in production with my default passwords, as that would be bad practice. ;-)


## My notes for running image mode demo on local laptop with KVM/Qemu guests

  * You need to have a working name resolution; that's why
    * I inject IP address and hostname of my podman VM into `/etc/hosts` of all VMs use during the demo
    * The hostname for the podman VM is used as container registry URL in
      * /etc/ostree/auth.json
      * /etc/containers/registries.conf.d/<some_name>.conf
      * The ostree kickstart file `ostreecontainer.ks`
  * It's important to specifiy the URL without 'https://' in kickstart file
