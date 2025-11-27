# Select base image based on target architecture (defaults to amd64).
ARG TARGETARCH=amd64

# Native amd64 image already ships with ROS noetic desktop full.
FROM osrf/ros:noetic-desktop-full AS amd64

# Build an arm64 ROS noetic desktop full rootfs from Ubuntu 18.04 (bionic).
FROM arm64v8/ubuntu:bionic AS arm64
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2 \
    lsb-release \
 && curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc -o /tmp/ros.asc \
 && apt-key add /tmp/ros.asc \
 && echo "deb [arch=arm64] http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ros-noetic-desktop-full \
 && rm -rf /var/lib/apt/lists/* /tmp/ros.asc

ENV ROS_DISTRO=noetic
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}
ENV PATH=${ROS_ROOT}/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/ros/${ROS_DISTRO}/lib
ENV PYTHONPATH=/opt/ros/${ROS_DISTRO}/lib/python3/dist-packages
SHELL ["/bin/bash", "-c"]
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /etc/bash.bashrc

FROM ${TARGETARCH}

# select bash as default shell
SHELL ["/bin/bash", "-c"]

# install catkin + wstool + glog_catkin
RUN apt update && apt install -y \
    build-essential \
    cmake \
    git \
    python3-catkin-tools \
    python3-wstool \
    libglpk-dev \
    autoconf \
    automake \
    libtool \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/${ROS_DISTRO}/setup.bash

# install system deps
RUN apt update && apt install libglpk-dev -y
RUN apt install -y libprotobuf-dev protobuf-compiler  libprotoc-dev
RUN apt-get install -y libgtest-dev

RUN apt install -y usbutils net-tools vim

# x11 forward
RUN apt install -y x11-apps

# Set the working directory
WORKDIR /usr/src
RUN mkdir -p qm_door_ws/src
WORKDIR /usr/src/qm_door_ws

RUN apt install -y liburdfdom-dev liboctomap-dev libassimp-dev
RUN sudo apt install ros-noetic-rqt-controller-manager
RUN sudo apt install ros-noetic-hpp-fcl
RUN sudo apt install ros-noetic-pinocchio

RUN catkin config -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Container display setting helper
RUN echo "export XAUTHORITY=$HOME/.xaut/.Xauthority" >> ~/.bashrc
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
