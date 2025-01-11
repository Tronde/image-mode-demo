FROM registry.redhat.io/rhel9/rhel-bootc:9.5
ADD index.html /var/www/html/index.html
RUN dnf -y install httpd \
    openssh-server \
    bind-utils \
    net-tools \
    chrony \
    vim-enhanced \
    man-pages \
    strace \
    lsof \
    tcpdump \
    bash-completion && \
    dnf clean all
RUN systemctl enable httpd sshd
