#!/bin/bash

WHEREAMI="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
. "${WHEREAMI}/functions.sh"

local_ip="192.168.1.226"
remote_ip="192.168.1.191"
vxlan_id="100"

bridge_name="br${vxlan_id}"

function write_lxc_config() {
  local container_name="$1"
  local bridge_name="$2"
  local mac_address="$3"

  cat << EOS | sudo tee "/var/lib/lxc/${container_name}/config" > /dev/null
# Distribution configuration
lxc.include = /usr/share/lxc/config/common.conf
lxc.arch = x86_64

# Container specific configuration
lxc.rootfs.path = dir:/var/lib/lxc/${container_name}/rootfs
lxc.uts.name = ${container_name}

# Network configuration
lxc.net.0.type = veth
lxc.net.0.link = ${bridge_name}
lxc.net.0.flags = up
lxc.net.0.name = eth0
lxc.net.0.veth.pair = ${container_name}
lxc.net.0.hwaddr = ${mac_address}
EOS
}

create_bridge "${bridge_name}"

create_lxc_container "joske" "download -- --dist archlinux --release current --arch amd64"
create_lxc_container "jefke" "download -- --dist archlinux --release current --arch amd64"

write_lxc_config "joske" "${bridge_name}" "ee:ec:fa:e9:56:01"
write_lxc_config "jefke" "${bridge_name}" "ee:ec:fa:e9:56:02"

start_lxc_container "joske"
start_lxc_container "jefke"

create_vxlan_tunnel "${vxlan_id}" "${local_ip}" "${remote_ip}"
