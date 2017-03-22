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
import matplotlib.pyplot as plt

import sys

class SrcRoute(Packet):
    name = "SrcRoute"
    fields_desc = [
        LongField("preamble", 0),
        IntField("num_valid", 0),
        IntField("serial_number", 0)
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
    if len(sys.argv) < 3:
        print "Usage: send.py [this_host] [target_group]"
        print "For example: send.py h1 group1"
        sys.exit(1)

    src = sys.argv[1]
    dst = sys.argv[2:]

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


    G = nx.Graph()
    for a, b in links:
        G.add_edge(a, b) 

    shortest_paths = nx.shortest_path(G)
    shortest_path = []
    for d in dst:
        shortest_path.append(shortest_paths[src][d])

    print "path is:", shortest_path

    port_list = []
    pl = []
    for sp in shortest_path:
        first = sp[1]
        for h in sp[2:]:
            pl.append(port_map[first][h])
            first = h
        port_list.append(pl)
        pl = []

    print "port list is:", port_list

    port_str = []
    ps = ""
    for pl in port_list:
        for p in pl:
            ps += chr(p)
        port_str.append(ps)
        ps = ""
    print "port string is:", port_str

    while(1):
        msg = raw_input("What do you want to send: ")

        # finding the route
        first = None
        ps = ""
        for pl in port_list:
            for p in pl:
                ps += chr(p)
            p = SrcRoute(num_valid = len(pl)) / ps / msg
            print p.show()
            sendp(p, iface = "eth0")
            ps = ""
            # print msg

if __name__ == '__main__':
    main()
