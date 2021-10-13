#!/bin/bash
swapoff -a
rmmod fastswap.ko
rmmod fastswap_rdma.ko
reboot
