#!/bin/bash

# Copyright 2013-present Barefoot Networks, Inc. 
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $THIS_DIR/../../env.sh

P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py

SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch

CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py

$P4C_BM_SCRIPT p4src/s1.p4 --json s1.json
$P4C_BM_SCRIPT p4src/s2.p4 --json s2.json
$P4C_BM_SCRIPT p4src/s3.p4 --json s3.json
$P4C_BM_SCRIPT p4src/s4.p4 --json s4.json
$P4C_BM_SCRIPT p4src/s5.p4 --json s5.json
$P4C_BM_SCRIPT p4src/s6.p4 --json s6.json
$P4C_BM_SCRIPT p4src/s7.p4 --json s7.json

# This gives libtool the opportunity to "warm-up"
sudo $SWITCH_PATH >/dev/null 2>&1
sudo PYTHONPATH=$PYTHONPATH:$BMV2_PATH/mininet/ python topo.py \
    --behavioral-exe $SWITCH_PATH \
    --json s1.json s2.json s3.json s4.json s5.json s6.json s7.json\
    --cli $CLI_PATH \
