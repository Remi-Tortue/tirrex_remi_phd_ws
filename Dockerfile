ARG FROM_IMAGE

FROM ${FROM_IMAGE}

# install all missing packages that you have specified into your package.xml
RUN --mount=type=bind,source=src,target=/tmp/src \
    apt-get update && \
    rosdep update && \
    rosdep install -iyr --from-paths /tmp/src && \
    rm -rf /var/lib/apt/lists/*


# --------------------------------------------------------------------------
# Base apt dependencies
# --------------------------------------------------------------------------
# you can add here ubuntu packages that you want to install (or uncomment the existing ones)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      # gdb \
      # gdbserver \
      # valgrind \
      # strace \
    ros-jazzy-pcl-ros \
    ros-jazzy-pcl-conversions \
    ros-jazzy-plotjuggler \
    ros-jazzy-plotjuggler-ros \
    # ros-jazzy-open3d-conversions \
    wget \
    # snapd \
    # for acados C library installation
    && rm -rf /var/lib/apt/lists/*

# RUN snap install plotjuggler


# --------------------------------------------------------------------------
# Base Python dependencies
# --------------------------------------------------------------------------
RUN apt-get remove -y python3-matplotlib || true
RUN pip install --no-cache-dir --ignore-installed \
    "numpy<2" \
    "scipy<2" \
    "matplotlib" \
    "numpy-quaternion" \
    "opencv-python"



# --------------------------------------------------------------------------
# Pixi environments
# --------------------------------------------------------------------------

RUN wget -qO- https://pixi.sh/install.sh | PIXI_HOME=/usr/local bash

RUN pixi --version

COPY src/skeleton_detection /opt/skeleton_detection

WORKDIR /opt/skeleton_detection/
RUN pixi install --all && \
    pixi run -e default bash -c "colcon build"


# --------------------------------------------------------------------------
# Install o2r_pi2_controllers
# --------------------------------------------------------------------------
COPY src/gesture_command/third_party/o2r_pi2_controllers /opt/o2r_pi2_controllers

WORKDIR /opt/o2r_pi2_controllers
RUN pip install -e .


# --------------------------------------------------------------------------
# Install casadi version 3.7.2 for acados
# --------------------------------------------------------------------------
RUN pip install --no-cache-dir -v "casadi==3.7.2"

# --------------------------------------------------------------------------
# Install acados from o2r_pi2_controllers
# --------------------------------------------------------------------------
WORKDIR /opt/o2r_pi2_controllers/third_party/acados
RUN mkdir -p build && cd build && \
    cmake \
    -DACADOS_WITH_QPOASES=ON \
    DACADOS_WITH_OSQP=ON \
    DACADOS_WITH_DAQP=ON \
    DACADOS_WITH_QPDUNES=ON \
    BUILD_SHARED_LIBS=ON \
    .. && \
    make install -j$(nproc) && \
    pip install -e ../interfaces/acados_template && \
    wget -O t_renderer https://github.com/acados/tera_renderer/releases/download/v0.2.1/t_renderer-v0.2.1-linux-amd64 && \
    mkdir -p ../bin && \
    mv t_renderer ../bin/ && \
    chmod 755 ../bin/t_renderer

ENV ACADOS_SOURCE_DIR=/opt/o2r_pi2_controllers/third_party/acados
ENV LD_LIBRARY_PATH=/opt/o2r_pi2_controllers/third_party/acados/lib:${LD_LIBRARY_PATH}


