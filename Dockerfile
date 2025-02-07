# syntax=docker/dockerfile:1
FROM uwrov/sim_base:latest

RUN apt-get update && apt-get install -y \
  ros-noetic-xacro \
  ros-noetic-gazebo-ros-pkgs \
  ros-noetic-urdf \
  liburdfdom-tools \
  openssh-client openssh-server

# switch to /root
ENV DIRPATH /root
WORKDIR $DIRPATH

ENV GZWEB_PATH ${DIRPATH}/gzweb
ENV GZWEB_ASSETS ${DIRPATH}/gzweb/http/client/assets

COPY setup.sh /usr/share/gazebo/

# Build ros packages
RUN mkdir -p /root/catkin_ws/src
COPY src/nautilus_description catkin_ws/src/nautilus_description
COPY src/nautilus_worlds catkin_ws/src/nautilus_worlds
RUN . /opt/ros/noetic/setup.sh && cd /root/catkin_ws && catkin_make

RUN echo ". /usr/share/gazebo/setup.sh" >> /root/.bashrc
RUN echo "source /root/catkin_ws/devel/setup.bash" >> /root/.bashrc

# Set up ssh
RUN mkdir -p /var/run/sshd
RUN sed -i '/#PermitRootLogin .*/c\PermitRootLogin yes' /etc/ssh/sshd_config

RUN echo "root:passwhat"|chpasswd

COPY ros_setup.sh /root/ros_setup.sh
RUN chmod +x /root/ros_setup.sh

EXPOSE 8080

ENTRYPOINT service ssh restart && Xvfb :1 -screen 0 1600x1200x16 && bash