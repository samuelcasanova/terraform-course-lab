FROM hashicorp/terraform:latest

# Install AWS CLI and other useful tools
RUN apk add --no-cache \
    aws-cli \
    curl \
    jq \
    bash

# Set the working directory
WORKDIR /projects/terraform-course-lab

# Default command
ENTRYPOINT ["/bin/bash"]