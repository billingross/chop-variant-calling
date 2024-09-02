# Install Nextflow prerequisites
sudo apt intall unzip
sudo apt install zip

curl -s https://get.sdkman.io | bash
source "~/.sdkman/bin/sdkman-init.sh"

sdk install java 17.0.10-tem

# Install Nextflow
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin
nextflow info
nextflow self-update

# Add read access as well
# Reference: https://github.com/nextflow-io/nextflow/discussions/2956
sudo chmod 715 /usr/local/bin/nextflow
