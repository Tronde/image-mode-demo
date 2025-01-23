FROM registry.redhat.io/rhel9/rhel-bootc:9.5-1736459892
ADD index.html /var/www/html/index.html
RUN dnf -y install httpd \
    openssh-server \
    bind-utils \
    net-tools \
    chrony \
    vim-enhanced \
    man-pages \
    man-db \
    strace \
    lsof \
    tcpdump \
    bash-completion && \
    dnf clean all
RUN mandb
RUN systemctl enable httpd sshd
