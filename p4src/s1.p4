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

//修改包的出口
action s1_route(egress_spec) {
    modify_field(standard_metadata.egress_spec, egress_spec);
}

//丢掉不正确的包
table s1_check_pkt {
    reads {
        pkt_head: valid;
    }
    actions {
        _drop;
    }
    size: 1;
}

//匹配入口和group_id，匹配成功则修改包出口，不成功就丢掉.入口只有1和3合法.size为2.
table s1_route_pkt {
    reads {
        standard_metadata.ingress_port : exact;
        pkt_head.group_id : exact;
    }
    actions {
        _drop;
        s1_route;
    }
    size: 2;
}

control ingress {
    apply(s1_check_pkt) {
        miss { // If s1_check_pkt table matched, apply s1_route_pkt
             apply(s1_route_pkt);
         }
    }
}

control egress {
    // leave empty
}
