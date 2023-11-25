# Charmed Apache Superset ROCK

This repository contains the packaging metadata for creating a Charmed Superset ROCK. This ROCK image is based on the upstream [Apache Superset](https://downloads.apache.org/superset/) image.

For more information on ROCKs, visit the [rockcraft Github](https://github.com/canonical/rockcraft).

## Building the ROCK
The steps outlined below are based on the assumption that you are building the ROCK with the latest LTS of Ubuntu.  
If you are using another version of Ubuntu or another operating system, the process may be different. 
To avoid any issue with other operating systems you can simply build the image with [multipass](https://multipass.run/):
```bash
sudo snap install multipass
multipass launch 22.04 -n rock-dev
multipass shell rock-dev
``` 

### Clone Repository
```bash
git clone https://github.com/canonical/charmed-superset-rock.git
cd charmed-superset-rock
```
### Installing Prerequisites
```bash
sudo snap install rockcraft --edge --classic
sudo snap install docker
sudo snap install lxd
sudo snap install skopeo --edge --devmode
```
### Configuring Prerequisites
```bash
sudo usermod -aG docker $USER 
sudo lxd init --auto
```
*_NOTE:_* You will need to open a new shell for the group change to take effect (i.e. `su - $USER`)
### Packing and Running the ROCK
```bash
rockcraft pack
sudo skopeo --insecure-policy copy oci-archive:charmed-superset-rock_2.1.0_amd64.rock docker-daemon:/charmed-superset-rock:2.1.0
docker run -d --name superset-ui-services -p 8088:8088 charmed-superset-rock:2.1.0 --args superset-ui -g 'daemon off:' \; start superset-ui
```
## License
The Charmed Superset ROCK is free software, distributed under the Apache
Software License, version 2.0. See
[LICENSE](https://github.com/canonical/charmed-superset-rock/blob/main/LICENSE)
for more information.