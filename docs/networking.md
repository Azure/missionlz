# Networking

This repository has carefully planned default address spaces configured in Mission Landing Zone and the add-on virtual networks to prevent deployment conflicts. While we exepect most customers to define custom networking configurations, if you deploy everything "as-is", there are no overlapping address spaces. Here is how the default networking is broken down:

## Super Network

10.0.128.0/18

## Virtual Networks

| Solution | Network                              | Address Space |
| -------- | ------------------------------------ | --------------|
| MLZ      | Hub                                  | 10.0.128.0/23 |
| MLZ      | Identity                             | 10.0.130.0/24 |
| MLZ      | Operations                           | 10.0.131.0/24 |
| MLZ      | Shared Services                      | 10.0.132.0/24 |
| Add-On   | Tier 3                               | 10.0.133.0/24 |
| Add-On   | Imaging                              | 10.0.134.0/24 |
| Add-On   | ESRI Enterprise                      | 10.0.135.0/24 |
| Add-On   | Azure Virtual Desktop, Stamp Index 0 | 10.0.140.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 1 | 10.0.142.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 2 | 10.0.144.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 3 | 10.0.146.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 4 | 10.0.148.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 5 | 10.0.150.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 6 | 10.0.152.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 7 | 10.0.154.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 8 | 10.0.156.0/23 |
| Add-On   | Azure Virtual Desktop, Stamp Index 9 | 10.0.158.0/23 |
