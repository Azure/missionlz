# Networking

This repository has several default address spaces configured throughout the Mission Landing Zone and the various add-ons to prevent deployment conflicts. While we exepect most customers to define custom networking configurations, if you deploy everything "as-is", there are no overlapping address spaces. Here is how the default networking is broken down:

## Super Network

10.0.96.0/19

## Virtual Networks

| Solution | Network               | Address Space     |
| -------- | --------------------- | ----------------- |
| MLZ      | Hub                   | 10.0.100.0/24     |
| MLZ      | Identity              | 10.0.105.0/26     |
| MLZ      | Operations            | 10.0.110.0/26     |
| MLZ      | Shared Services       | 10.0.115.0/26     |
| Add-On   | Tier 3                | 10.0.120.0/24     |
| Add-On   | Imaging               | 10.0.125.0/24     |
| Add-On   | Azure Virtual Desktop | 10.0.130-139.0/24 |
