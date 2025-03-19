# Uses gcc8 for glibc 2.28
ARG FROM=conanio_builder:latest
FROM ${FROM} AS lanelet2_conan_deps

ENV DEBIAN_FRONTEND noninteractive

# install requirements for python installation
RUN apt-get update \
  && apt-get install -y libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl \
  libncursesw5-dev xz-utils libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev software-properties-common git

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN apt-get update \
  && apt-get install -y ros-humble-autoware-*

# setup python environment
ARG PY_VERSION=3.12
RUN curl https://pyenv.run | bash
ENV PYENV_ROOT /root/.pyenv
ENV PATH $PATH:$PYENV_ROOT/bin
RUN pyenv update \
  && pyenv install -s $PY_VERSION \
  && pyenv global $PY_VERSION
RUN pip install "conan~=2.8.0" catkin_pkg "numpy<2.0" wheel auditwheel cmake

# install patchelf
# RUN wget https://github.com/NixOS/patchelf/releases/download/0.17.2/patchelf-0.17.2-x86_64.tar.gz \
#   && tar -xzf patchelf-0.17.2-x86_64.tar.gz \
#   && ln -s $HOME/bin/patchelf /bin/patchelf \
#   && patchelf --version


# FROM lanelet2_conan_deps as lanelet2_conan_src

# # checkout code
RUN mkdir src
WORKDIR /root/src
COPY --chown=1000:1001 . lanelet2/

# FROM lanelet2_conan_src as lanelet2_conan

# compile
ARG CONAN_ARGS=""
ARG PLATFORM="manylinux_2_31_x86_64"
WORKDIR /root/src/lanelet2
# RUN conan profile detect
RUN conan create . --format=json --build=missing -o "&:build_wheel=True" -o "&:platform=${PLATFORM}" ${CONAN_ARGS} > conaninfo.json

# # obtain wheel
# FROM lanelet2_conan as lanelet2_conan_with_pip_wheel

# SHELL ["/bin/bash", "-c"]
# WORKDIR /root
# RUN LANELET2_PACKAGE_DIR=$(python3 -c "import json; f=open('src/lanelet2/conaninfo.json'); data=json.load(f); ll2=next(d for d in data['graph']['nodes'].values() if 'lanelet2' in d['ref']); print(f'{ll2[\"package_folder\"]}/wheel')") \
#   && cp -r $LANELET2_PACKAGE_DIR dist

# to extract the wheel manually run:
# $ docker run --rm -v /path/to/some/local/folder:/dist <image> /bin/bash -c 'sudo cp dist/lanelet2-<...>.whl /dist/.'