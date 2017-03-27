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

//元数据用来保存序号
header_type ingress_metadata_t {
    fields {
	sequence_number : 32;
        
    }
}

metadata ingress_metadata_t ingress_data;

//register用来保存group的序号，因为只有一个group，所以也只要一个register
register sequence_number {
    width : 32;
    instance_count : 1;
}

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

//不做任何操作
action no_op() {
    
}

//执行加1和多播给s1，s2. intrinsic_metadata.mcast_grp不为0就会设置多播，多播编号为mcast_group
action s3_route(mcast_group) {
    //执行加1
    register_read(ingress_data.sequence_number, sequence_number, 0);
    modify_field(pkt_head.sequence_number, ingress_data.sequence_number);
    add_to_field(ingress_data.sequence_number, 1);
    register_write(sequence_number, 0, ingress_data.sequence_number);
    //通过修改intrinsic_metadata.mcast_grp执行多播
    modify_field(intrinsic_metadata.mcast_grp, mcast_group);
}

//检查包是否正确，不正确就丢掉
table s3_check_pkt {
    reads {
        pkt_head: valid;
    }
    actions {
        _drop;
        no_op;
    }
    size: 1;
}

//匹配group_id，成功则进行加1操作并设置多播；不成功丢掉
table s3_route_pkt {
    reads {
        pkt_head.group_id: exact;
    }
    actions {
        s3_route; 
	_drop;
    }
    size : 1;
}

control ingress {
    apply(s3_check_pkt);
    apply(s3_route_pkt);
}

control egress {
    // leave empty
}
