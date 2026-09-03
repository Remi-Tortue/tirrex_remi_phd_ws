#!/bin/bash
export LD_LIBRARY_PATH=/opt/o2r_pi2_controllers/third_party/acados/lib:$LD_LIBRARY_PATH
export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:src/gazebo_procedural_world_generation/src/gazebo_procedural_world_generation/models:src/phd_experiment_config/worlds:src/ArUco_gazebo_tiles/models
exec bash