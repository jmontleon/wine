# Explanation
There is no i686 buildroot for EL8 in Copr or EPEL, so it is difficult to build wine.i686 to support 32-bit applications.

This Dockerfile does some editing of RPM specs to facilitate building a recent wine on CentOS 8 for both x86_64 and i686.

# Usage
`sudo dnf config-manager --set-enabled powertools`   
`podman cp $(podman create quay.io/jmontleon/wine:latest):/RPMS/ ./`  
`cd RPMS `  
```
sudo dnf install -y ./wine-7*x86_64* \
                    ./wine-alsa-7*x86_64* \
                    ./wine-cms-7*x86_64* \
                    ./wine-core-7*x86_64* \
                    ./wine-ldap-7*x86_64* \
                    ./wine-openal-7*x86_64* \
                    ./wine-pulseaudio-7*x86_64* \
                    ./wine-twain-7*x86_64* \
                    ./wine-7*i686* \
                    ./wine-core-7*i686* \
                    ./wine-common* \
                    ./wine-desktop-7* \
                    ./wine-filesystem-7* \
                    ./wine-systemd-7* \
                    ./wine-*fonts* \
                    ./libvkd3d-1*x86_64* \
                    ./libvkd3d-1*i686* \
                    ./libvkd3d-shader-1*x86_64* \
                    ./libvkd3d-shader-1*i686*
```

# Default wine version
You can switch whether `wine32` or `wine64` is run when you run `wine` using alternatives.  

With wine-core.i686 installed you should be able to run 32-bit applications using wine64.  

```
alternatives --config wine

There are 2 programs which provide 'wine'.

  Selection    Command
-----------------------------------------------
   1           /usr/bin/wine64
*+ 2           /usr/bin/wine32

Enter to keep the current selection[+], or type selection number: 
```

32-bit apps to test include Steam and Notepad++

# SRPMs
Source RPMs can be retrieved from the image like the binary RPMs
`podman cp $(podman create quay.io/jmontleon/wine:latest):/SRPMS/ ./`
