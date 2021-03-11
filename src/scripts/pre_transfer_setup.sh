#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
#
# This script deploys container registries, app registrations, and a container instance to run the MLZ front end
#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
#
# This script dumps the docker image and compresses it for transport to a target network


# Run Docker Setup Script

docker save -o mlz.tar lzfront:latest
zip mlz.zip mlz.tar
rm mlz.tar
