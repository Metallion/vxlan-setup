#!/bin/bash

WHEREAMI="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
. "${WHEREAMI}/functions.sh"

local_ip="192.168.1.191"
remote_ip="192.168.1.226"
vxlan_id="100"
host_interface="enp1s0"

bridge_name="br${vxlan_id}"

function write_lxc_config() {
  local container_name="$1"
  local bridge_name="$2"
  local mac_address="$3"

  cat << EOS | sudo tee "/var/lib/lxc/${container_name}/config" > /dev/null
# Template used to create this container: /usr/share/lxc/templates/lxc-centos
# Parameters passed to the template:
# For additional config options, please look at lxc.container.conf(5)
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = ${bridge_name}
lxc.network.veth.pair = ${container_name}
lxc.network.hwaddr = ${mac_address}
lxc.rootfs = /var/lib/lxc/${container_name}/rootfs

# Include common configuration
lxc.include = /usr/share/lxc/config/centos.common.conf

lxc.arch = x86_64
lxc.utsname = ${container_name}

lxc.autodev = 1
EOS
}

create_bridge "${bridge_name}"

create_lxc_container "jantje" "download -- --dist archlinux --release current --arch amd64"
create_lxc_container "jossefien" "download -- --dist archlinux --release current --arch amd64"

write_lxc_config "jantje" "${bridge_name}" "ee:ec:fa:e9:57:01"
write_lxc_config "jossefien" "${bridge_name}" "ee:ec:fa:e9:57:02"

start_lxc_container "jantje"
start_lxc_container "jossefien"

create_vxlan_tunnel "${vxlan_id}" "${local_ip}" "${remote_ip}" "${host_interface}"
