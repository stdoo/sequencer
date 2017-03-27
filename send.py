#!/usr/bin/python
#-*- coding: utf-8 -*-
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

from scapy.all import sniff, sendp
from scapy.all import Packet
from scapy.all import ShortField, IntField, LongField, BitField

import networkx as nx

import sys

class SrcRoute(Packet):
    name = "SrcRoute"
    fields_desc = [
        ShortField("preamble", 0),
        ShortField("group_id", 0),
        IntField("sequence_number", 0)
    ]

def read_topo():
    nb_hosts = 0
    nb_switches = 0
    links = []
    with open("topo.txt", "r") as f:
        line = f.readline()[:-1]
        w, nb_switches = line.split()
        assert(w == "switches")
        line = f.readline()[:-1]
        w, nb_hosts = line.split()
        assert(w == "hosts")
        for line in f:
            if not f: break
            a, b = line.split()
            links.append( (a, b) )
    return int(nb_hosts), int(nb_switches), links

def main():
    nb_hosts, nb_switches, links = read_topo()
    port_map = {}

    for a, b in links:
        if a not in port_map:
            port_map[a] = {}
        if b not in port_map:
            port_map[b] = {}

        assert(b not in port_map[a])
        assert(a not in port_map[b])
        port_map[a][b] = len(port_map[a]) + 1
        port_map[b][a] = len(port_map[b]) + 1 

    while(1):
        msg = raw_input("What do you want to send: ")

        # finding the route
        first = None

        p = SrcRoute() / msg
        print p.show()
        sendp(p, iface = "eth0")
        # print msg

if __name__ == '__main__':
    main()
