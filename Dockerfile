FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Etc/UTC

RUN echo 'root:root' | chpasswd

RUN sed -i s@/archive.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list && apt-get clean && \
    apt-get update && \
    apt-get install -y python3-pip python3-pexpect unzip busybox-static fakeroot kpartx snmp uml-utilities util-linux vlan qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils wget tar lsb-core libjpeg-dev zlib1g-dev sudo && \
    apt-get autoremove --yes && rm -rf /var/lib/apt/lists/*

WORKDIR /root/firmware-analysis-toolkit

COPY binwalk ./binwalk

# Binwalk
RUN ls && cd binwalk && \
    sed -i 's;\$SUDO ./build.sh;wget https://github.com/devttys0/sasquatch/pull/47.patch \&\& patch -p1 < 47.patch \&\& \$SUDO ./build.sh;' deps.sh && \
    sed -i '/REQUIRED_UTILS="wget tar python"/c\REQUIRED_UTILS="wget tar python3"' deps.sh && \
    apt-get update && ./deps.sh --yes && apt-get autoremove --yes && rm -rf /var/lib/apt/lists/*

RUN cd binwalk && python3 ./setup.py install && \
    pip3 install --no-cache-dir python-magic jefferson

# QEMU
RUN mkdir qemu-builds &&  cd qemu-builds && \
    wget -O qemu-system-static-2.0.0.zip "https://github.com/attify/firmware-analysis-toolkit/files/9937453/qemu-system-static-2.0.0.zip" && \
    unzip -qq qemu-system-static-2.0.0.zip && rm qemu-system-static-2.0.0.zip && \
    wget -O qemu-system-static-2.5.0.zip "https://github.com/attify/firmware-analysis-toolkit/files/4244529/qemu-system-static-2.5.0.zip" && \
    unzip -qq qemu-system-static-2.5.0.zip && rm qemu-system-static-2.5.0.zip && \
    wget -O qemu-system-static-3.0.0.tar.gz "https://github.com/attify/firmware-analysis-toolkit/files/9937487/qemu-system-static-3.0.0.tar.gz" && \
    tar xf qemu-system-static-3.0.0.tar.gz && rm qemu-system-static-3.0.0.tar.gz

COPY firmadyne ./firmadyne

# Setup firmadyne
RUN cd firmadyne && sed -i "/FIRMWARE_DIR=/c\FIRMWARE_DIR=$(realpath .)" firmadyne.config

COPY fat.py fat.config reset.py ./

# Setup FAT
RUN chmod +x fat.py reset.py && \
    sed -i "/firmadyne_path=/c\firmadyne_path=$(realpath firmadyne)" fat.config

CMD [ "bash" ]