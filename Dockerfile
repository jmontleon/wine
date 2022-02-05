FROM quay.io/centos/centos:stream8 as builder
RUN dnf config-manager --set-enabled powertools

# Install Basic Requirements, link is for a GCC8 bug
RUN dnf -y install rpm-build wget glibc-devel.i686 libstdc++-devel.i686
RUN ln -sf /usr/include/c++/8/i686-redhat-linux/bits/* /usr/include/c++/8/bits/ 

# Get latest packages
RUN dnf download --source p11-kit
RUN echo -ne "[rawhide]\nname=rawhide\nbaseurl=https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/source/tree\ngpgcheck=0" > /etc/yum.repos.d/fedora-rawhide-source.repo
RUN dnf download --source --disablerepo='*' --enablerepo=rawhide --source FAudio audiofile spirv-headers vkd3d wine
RUN rpm -ivh ./*.rpm

# Build and install p11-kit with fix
RUN sed -i 's/libtasn1-devel/libtasn1-devel(x86-32)/g' /root/rpmbuild/SPECS/p11-kit.spec
RUN sed -i 's/libffi-devel/libffi-devel(x86-32)/g' /root/rpmbuild/SPECS/p11-kit.spec
RUN sed -i 's/systemd-devel/systemd-devel(x86-32)/g' /root/rpmbuild/SPECS/p11-kit.spec
RUN sed -i 's/%{_mandir}\/man1\/trust.1.gz/%exclude %{_mandir}\/man1\/trust.1.gz/g' /root/rpmbuild/SPECS/p11-kit.spec
RUN sed -i 's/%{_mandir}\/man8\/p11-kit.8.gz/%exclude %{_mandir}\/man8\/p11-kit.8.gz/g' /root/rpmbuild/SPECS/p11-kit.spec
RUN sed -i 's/%{_mandir}\/man5\/pkcs11.conf.5.gz/%exclude %{_mandir}\/man5\/pkcs11.conf.5.gz/g' /root/rpmbuild/SPECS/p11-kit.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/p11-kit.spec
RUN rpmbuild -ba --target=i686 /root/rpmbuild/SPECS/p11-kit.spec
RUN dnf -y install /root/rpmbuild/RPMS/i686/p11-kit-0* /root/rpmbuild/RPMS/i686/p11-kit-devel*


# Build and install spirv-headers-devel
RUN rpmbuild -ba /root/rpmbuild/SPECS/spirv-headers.spec
RUN dnf -y install /root/rpmbuild/RPMS/noarch/spirv-headers-devel*

# Build and install FAudio-devel
RUN dnf builddep -y /root/rpmbuild/SPECS/FAudio.spec
RUN rpmbuild -ba /root/rpmbuild/SPECS/FAudio.spec
RUN sed -i 's/SDL2-devel/SDL2-devel(x86-32)/g' /root/rpmbuild/SPECS/FAudio.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/FAudio.spec
RUN rpmbuild -ba --target=i686 /root/rpmbuild/SPECS/FAudio.spec
RUN dnf -y install /root/rpmbuild/RPMS/i686/libFAudio-2* /root/rpmbuild/RPMS/i686/libFAudio-devel*
RUN dnf -y install /root/rpmbuild/RPMS/x86_64/libFAudio-2* /root/rpmbuild/RPMS/x86_64/libFAudio-devel*

# Build and install audiofile-devel
RUN dnf builddep -y /root/rpmbuild/SPECS/audiofile.spec
RUN rpmbuild -ba /root/rpmbuild/SPECS/audiofile.spec
RUN sed -i 's/alsa-lib-devel/alsa-lib-devel(x86-32)/g' /root/rpmbuild/SPECS/audiofile.spec
RUN sed -i 's/flac-devel/flac-devel(x86-32)/g' /root/rpmbuild/SPECS/audiofile.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/audiofile.spec
RUN rpmbuild -ba --target=i686 /root/rpmbuild/SPECS/audiofile.spec
RUN dnf -y install /root/rpmbuild/RPMS/i686/audiofile-0* /root/rpmbuild/RPMS/i686/audiofile-devel*
RUN dnf -y install /root/rpmbuild/RPMS/x86_64/audiofile-0* /root/rpmbuild/RPMS/x86_64/audiofile-devel*

# Build and install vkd3d-devel
RUN dnf builddep -y /root/rpmbuild/SPECS/vkd3d.spec
RUN rpmbuild -ba /root/rpmbuild/SPECS/vkd3d.spec
RUN sed -i 's/libxcb-devel/libxcb-devel(x86-32)/g' /root/rpmbuild/SPECS/vkd3d.spec
RUN sed -i 's/spirv-tools-devel/spirv-tools-devel(x86-32)/g' /root/rpmbuild/SPECS/vkd3d.spec
RUN sed -i 's/vulkan-loader-devel/vulkan-loader-devel(x86-32)/g' /root/rpmbuild/SPECS/vkd3d.spec
RUN sed -i 's/xcb-util-devel/xcb-util-devel(x86-32)/g' /root/rpmbuild/SPECS/vkd3d.spec
RUN sed -i 's/xcb-util-keysyms-devel/xcb-util-keysyms-devel(x86-32)/g' /root/rpmbuild/SPECS/vkd3d.spec
RUN sed -i 's/xcb-util-wm-devel/xcb-util-wm-devel(x86-32)/g' /root/rpmbuild/SPECS/vkd3d.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/vkd3d.spec
RUN rpmbuild -ba --target=i686 /root/rpmbuild/SPECS/vkd3d.spec
RUN dnf -y install /root/rpmbuild/RPMS/i686/libvkd3d-1* /root/rpmbuild/RPMS/i686/libvkd3d-devel* \
    /root/rpmbuild/RPMS/i686/libvkd3d-shader-1* /root/rpmbuild/RPMS/i686/libvkd3d-shader-devel*
RUN dnf -y install /root/rpmbuild/RPMS/x86_64/libvkd3d-1* /root/rpmbuild/RPMS/x86_64/libvkd3d-devel* \
    /root/rpmbuild/RPMS/x86_64/libvkd3d-shader-1* /root/rpmbuild/RPMS/x86_64/libvkd3d-shader-devel*

# Build and install wine
# There is a bug in a case statement fixed by a newer wine-staging. There might be a better way to do this. It's kinda gross.
WORKDIR /root/rpmbuild/SOURCES
RUN wget https://github.com/wine-staging/wine-staging/archive/refs/heads/master.tar.gz
RUN tar zxvf master.tar.gz \
 && tar zxvf wine-staging-7.1.tar.gz \
 && mv wine-staging-7.1/patches/shell32-IconCache/0001-shell32-iconcache-Generate-icons-from-available-icons-.patch wine-staging-master/patches/shell32-IconCache/ \
 && mv wine-staging-7.1/patches/shell32-NewMenu_Interface/0001-shell32-Implement-NewMenu-with-new-folder-item.patch wine-staging-master/patches/shell32-NewMenu_Interface \
 && rm -rf wine-staging-7.1 \
 && mv wine-staging-master wine-staging-7.1
RUN rm -f wine-staging-7.1.tar.gz
RUN tar zcvf wine-staging-7.1.tar.gz wine-staging-7.1
# End of wine-staging update
# Build x86_64
RUN sed -i '1694d;1692d;168d;166d;28d;26d' /root/rpmbuild/SPECS/wine.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/wine.spec
RUN rpmbuild -ba /root/rpmbuild/SPECS/wine.spec && rm -rf /root/rpmbuild/BUILD/wine-7.1
# Build i686
RUN sed -i 's/alsa-lib-devel/alsa-lib-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/audiofile-devel/audiofile-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/freeglut-devel/freeglut-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/lcms2-devel/lcms2-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libieee1284-devel/libieee1284-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libjpeg-devel/libjpeg-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libpng-devel/libpng-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/librsvg2-devel/librsvg2-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libstdc++-devel/libstdc++-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libusb-devel/libusbx-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libxml2-devel/libxml2-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libxslt-devel/libxslt-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/ocl-icd-devel/ocl-icd-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/openldap-devel/openldap-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/unixODBC-devel/unixODBC-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/sane-backends-devel/sane-backends-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/systemd-devel/systemd-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/zlib-devel/zlib-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/fontforge/fontforge(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/freetype-devel/freetype-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libgphoto2-devel/libgphoto2-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/isdn4k-utils-devel/isdn4k-utils-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libpcap-devel/libpcap-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libX11-devel/libX11-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/mesa-libGL-devel/mesa-libGL-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/mesa-libGLU-devel/mesa-libGLU-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/mesa-libOSMesa-devel/mesa-libOSMesa-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXxf86dga-devel/libXxf86dga-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXxf86vm-devel/libXxf86vm-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXrandr-devel/libXrandr-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXrender-devel/libXrender-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXext-devel/libXext-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXinerama-devel/libXinerama-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXcomposite-devel/libXcomposite-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/fontconfig-devel/fontconfig-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/giflib-devel/giflib-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/cups-devel/cups-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXmu-devel/libXmu-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXi-devel/libXi-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libXcursor-devel/libXcursor-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/dbus-devel/dbus-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/gnutls-devel/gnutls-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/pulseaudio-libs-devel/pulseaudio-libs-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/gsm-devel/gsm-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libv4l-devel/libv4l-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libtiff-devel/libtiff-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/gettext-devel/gettext-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/gstreamer1-devel/gstreamer1-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/gstreamer1-plugins-base-devel/gstreamer1-plugins-base-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/mpg123-devel/mpg123-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/SDL2-devel/SDL2-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libvkd3d-devel/libvkd3d-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libvkd3d-shader-devel/libvkd3d-shader-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/vulkan-devel/vulkan-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libFAudio-devel/libFAudio-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/gtk3-devel/gtk3-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libattr-devel/libattr-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/libva-devel/libva-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/openal-soft-devel/openal-soft-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/wine.spec
RUN rpmbuild -ba --target=i686 /root/rpmbuild/SPECS/wine.spec
RUN dnf -y install /root/rpmbuild/RPMS/x86_64/wine-7* /root/rpmbuild/RPMS/noarch/wine-common-7* \
                   /root/rpmbuild/RPMS/noarch/wine-desktop-7* /root/rpmbuild/RPMS/noarch/wine-*fonts-7* \
                   /root/rpmbuild/RPMS/x86_64/wine-core-7* /root/rpmbuild/RPMS/i686/wine-core-7* \
                   /root/rpmbuild/RPMS/noarch/wine-filesystem-7* /root/rpmbuild/RPMS/noarch/wine-systemd-7* \
                   /root/rpmbuild/RPMS/x86_64/wine-cms-7* /root/rpmbuild/RPMS/x86_64/wine-ldap-7* \
                   /root/rpmbuild/RPMS/x86_64/wine-openal-7* /root/rpmbuild/RPMS/x86_64/wine-pulseaudio-7* \
                   /root/rpmbuild/RPMS/x86_64/wine-twain-7* /root/rpmbuild/RPMS/x86_64/wine-alsa-7*

FROM quay.io/centos/centos:stream8
COPY --from=builder /root/rpmbuild/RPMS/x86_64/* /RPMS/
COPY --from=builder /root/rpmbuild/RPMS/i686/* /RPMS/
COPY --from=builder /root/rpmbuild/RPMS/noarch/* /RPMS/
COPY --from=builder /root/rpmbuild/SRPMS/* /SRPMS/
