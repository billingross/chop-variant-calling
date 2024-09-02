# Install Nextflow prerequisites
sudo apt install unzip zip

curl -s https://get.sdkman.io | bash
source ~/.sdkman/bin/sdkman-init.sh

sdk install java 17.0.10-tem

# Install Nextflow
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin
nextflow info

# Add read access as well
# Reference: https://github.com/nextflow-io/nextflow/discussions/2956
sudo chmod 715 /usr/local/bin/nextflow

nextflow run hello

# Prepare to run sarek variant calling workflow
mkdir sarek-chop-output

## Install Docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Update Docker permissions for Nextflow
sudo chmod 666 /var/run/docker.sock

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


