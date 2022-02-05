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
RUN sed -i '1694d;1692d;168d;166d;28d;26d' /root/rpmbuild/SPECS/wine.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/wine.spec
RUN rpmbuild -ba /root/rpmbuild/SPECS/wine.spec && rm -rf /root/rpmbuild/BUILD/wine-7.1
RUN sed -i 's/-devel/-devel(x86-32)/g' /root/rpmbuild/SPECS/wine.spec
RUN sed -i 's/fontpackages-devel(x86-32)/fontpackages-devel/g' /root/rpmbuild/SPECS/wine.spec
RUN dnf builddep -y /root/rpmbuild/SPECS/wine.spec
RUN rpmbuild -ba --target=i686 /root/rpmbuild/SPECS/wine.spec

FROM quay.io/centos/centos:stream8
COPY --from=builder /root/rpmbuild/RPMS/x86_64/* /RPMS/
COPY --from=builder /root/rpmbuild/RPMS/i686/* /RPMS/
COPY --from=builder /root/rpmbuild/RPMS/noarch/* /RPMS/
COPY --from=builder /root/rpmbuild/SRPMS/* /SRPMS/
