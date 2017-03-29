/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

//用来设置多播的元数据
header_type intrinsic_metadata_t {
    fields {
        mcast_grp : 16;                        /* multicast group */
        lf_field_list : 32;                    /* Learn filter field list */
        egress_rid : 16;                       /* replication index */
        ingress_global_timestamp : 32;
    }
}
metadata intrinsic_metadata_t intrinsic_metadata;

//包头：preamble用来识别包，group_id用来识别group
header_type pkt_head_t {
    fields {
        preamble: 16;
        group_id: 16;
        sequence_number: 32;
    }
}

header pkt_head_t pkt_head;

//判断包的前16位，如果为0，说明包没错，可以解析包头
parser start {
    return select(current(0, 16)) {
        0: parse_head;
        default: ingress;
    }
}

//执行解析
parser parse_head {
    extract(pkt_head);
    return ingress;
}

//丢包操作
action _drop() {
    drop();
}

//上传packet
action s5_route(egress_spec) {
    modify_field(standard_metadata.egress_spec, egress_spec);
}

//执行多播
action s5_mc_route(mcast_group) {
    modify_field(intrinsic_metadata.mcast_grp, mcast_group);
}

//丢掉不正确的包
table s5_check_pkt {
    reads {
        pkt_head: valid;
    }
    actions {
        _drop;
    }
    size: 1;
}

//匹配group_id和ingress_port,成功则上传
table s5_route_pkt {
    reads {
        standard_metadata.ingress_port : exact;
        pkt_head.group_id : exact;
    }
    actions {
        _drop;
        s5_route;
    }
    size: 1;
}

//匹配group_id和ingress_port，成功则执行多播
table s5_mc_pkt {
    reads {
        standard_metadata.ingress_port : exact;
        pkt_head.group_id : exact;
    }
    actions {
        _drop;
        s5_mc_route;
    }
    size: 1;
}

control ingress {
    apply(s5_check_pkt) {
        miss { // If s5_check_pkt table miss, apply s5_route_pkt
             apply(s5_route_pkt){
                 miss {
                     apply(s5_mc_pkt);
                 }
             }
         }
    }
}

control egress {
    // leave empty
}
