#!/bin/bash

WHEREAMI="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
. "${WHEREAMI}/bashsteps/simple-defaults-for-bashsteps.source"

local_ip="192.168.1.226"
remote_ip="192.168.1.191"

vxlan_id="100"

function create_lxc_container() {
  local name="$1"
  local template="$2"

  (
    $starting_step "Create LXC container"
    sudo lxc-info -n "${name}" > /dev/null 2>&1
    $skip_step_if_already_done; set -xe
    lxc-create -n "${name}" -t ${template}
  ) ; prev_cmd_failed
}

function start_lxc_container() {
  local name="$1"

  (
    $starting_step "start LXC container"
    [ "$(sudo lxc-info -sn ${name})" == "State:          RUNNING" ]
    $skip_step_if_already_done; set -xe
    sudo lxc-start -dn "${name}"
  ) ; prev_cmd_failed
}

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

bridge_name="br${vxlan_id}"
(
  $starting_step "Create bridge ${bridge_name}"
  brctl show | grep -q "${bridge_name}"
  $skip_step_if_already_done; set -xe
  sudo brctl addbr "${bridge_name}"
  sudo ip link set "${bridge_name}" up
) ; prev_cmd_failed

create_lxc_container "joske" "download -- --dist archlinux --release current --arch amd64"
create_lxc_container "jefke" "download -- --dist archlinux --release current --arch amd64"

write_lxc_config "joske" "${bridge_name}" "ee:ec:fa:e9:56:01"
write_lxc_config "joske" "${bridge_name}" "ee:ec:fa:e9:56:02"

start_lxc_container "joske"
start_lxc_container "jefke"

vxlan_interface="vxlan${vxlan_id}"
(
  $starting_step "Create VxLAN tunnel"
  ip link show "${vxlan_interface}" > /dev/null 2>&1
  $skip_step_if_already_done; set -xe
  sudo ip link add "${vxlan_interface}" type vxlan id "${vxlan_id}" dstport 4789 local "${local_ip}" remote "${remote_ip}" dev eth0
  sudo ip link set "${vxlan_interface}" up
  sudo brctl addif "br${vxlan_id}" "${vxlan_interface}"
) ; prev_cmd_failed
