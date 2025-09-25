# Why this directory ?

There is a bug in the SELinux policy that prevents a Systemd service from touching kubernetes_file_t files.
So there is a symlink in /etc/microshift/manifests.d that points to this directory.
And /usr/local/bin/bootstrap-microshift.sh writes to this directory (/etc/crazy-train).

Sorry about that!
