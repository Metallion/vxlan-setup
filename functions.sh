#!/bin/bash

WHEREAMI="$(cd "$(dirname $(readlink -f "$0"))" && pwd -P)"
. "${WHEREAMI}/bashsteps/simple-defaults-for-bashsteps.source"

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

function create_bridge() {
  local bridge_name="$1"

  (
    $starting_step "Create bridge ${bridge_name}"
    brctl show | grep -q "${bridge_name}"
    $skip_step_if_already_done; set -xe
    sudo brctl addbr "${bridge_name}"
    sudo ip link set "${bridge_name}" up
  ) ; prev_cmd_failed
}

function create_vxlan_tunnel() {
  local vxlan_id="$1"
  local local_ip="$2"
  local remote_ip="$3"
  local host_interface="$4"

  local vxlan_interface="vxlan${vxlan_id}"

  (
    $starting_step "Create VxLAN tunnel"
    ip link show "${vxlan_interface}" > /dev/null 2>&1
    $skip_step_if_already_done; set -xe
    sudo ip link add "${vxlan_interface}" type vxlan id "${vxlan_id}" dstport 4789 local "${local_ip}" remote "${remote_ip}" dev "${host_interface}"
    sudo ip link set "${vxlan_interface}" up
    sudo brctl addif "br${vxlan_id}" "${vxlan_interface}"
  ) ; prev_cmd_failed
}
