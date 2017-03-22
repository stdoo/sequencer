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

header_type sequencer_head_t {
    fields {
        preamble: 64;
        num_valid: 32;
        serial_number: 32;
    }
}

header sequencer_head_t sequencer_head;

header_type sequencer_port_t {
    fields {
        port: 8;
    }
}

header sequencer_port_t sequencer_port;

header_type ingress_metadata_t {
    fields {
	serial_number : 32;
    }
}

metadata ingress_metadata_t ingress_data;

register serial_number {
    width : 32;
    instance_count : 1;
}

parser start {
    return select(current(0, 64)) {
        0: parse_head;
        default: ingress;
    }
}

parser parse_head {
    extract(sequencer_head);
    return select(latest.num_valid) {
        0: ingress;
        default: parse_port;
    }
}

parser parse_port {
    extract(sequencer_port);
    return ingress;
}

action _drop() {
    drop();
}

action route() {
    modify_field(standard_metadata.egress_spec, sequencer_port.port);
    add_to_field(sequencer_head.num_valid, -1);
    remove_header(sequencer_port);

    register_read(ingress_data.serial_number, serial_number, 0);
    modify_field(sequencer_head.serial_number, ingress_data.serial_number);
    add_to_field(ingress_data.serial_number, 1);
    register_write(serial_number, 0, ingress_data.serial_number);
}

table route_pkt {
    reads {
        sequencer_port: valid;
    }
    actions {
        _drop;
        route;
    }
    size: 1;
}

control ingress {
    apply(route_pkt);
}

control egress {
    // leave empty
}
