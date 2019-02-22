# VxLAN Setup

These are just some simple scripts to set up a VxLAN tunnel between two hosts with 2 LXC containers on each side.

Host 1 is my Arch Linux laptop.
Host 2 is a server running Centos 7.

The scripts are simple enough so just adjust them to work on your environment. The main difference between Arch and Centos was the LXC version. Had to use a different template on each and also the veth part of the config file was slightly different.
