# Variables
REPO_FOLDER = charmed-superset-rock
REPO = https://github.com/canonical/$(REPO_FOLDER).git
ROCK_DEV = rock-dev
ROCK_VERSION = 2.1.0
UBUNTU_VER = 22.04
DOCKER_NAME = superset-ui-services
DOCKER_PORT = 8088
DOCKER_ARGS = superset-ui -g 'daemon off:' \; start superset-ui

# Targets
.PHONY: all
all: install-multipass setup-multipass clone install-prerequisites configure-prerequisites pack run

.PHONY: dev
dev: install-multipass setup-multipass clone install-prerequisites configure-prerequisites

.PHONY: build
build: pack

.PHONY: install
install: run

.PHONY: clean
clean:
	multipass delete $(ROCK_DEV) && multipass purge

.PHONY: install-multipass
install-multipass:
	sudo snap install multipass

.PHONY: setup-multipass
setup-multipass:
	multipass launch $(UBUNTU_VER) -n $(ROCK_DEV) -m 8g -c 2 -d 20G

.PHONY: clone
clone:
	multipass exec $(ROCK_DEV) -- git clone $(REPO)

.PHONY: install-prerequisites
install-prerequisites:
	multipass exec $(ROCK_DEV) -- bash -c 'sudo snap install rockcraft --edge --classic &&\
	sudo snap install skopeo --edge --devmode &&\
	sudo snap install lxd && sudo lxd init --auto'
	multipass exec $(ROCK_DEV) -- sudo snap install docker

.PHONY: configure-prerequisites
configure-prerequisites:
	multipass exec $(ROCK_DEV) -- bash -c 'if getent group docker > /dev/null; then echo "The docker group exists"; else sudo groupadd docker && echo "The docker group has been created"; fi; sudo usermod -aG docker $$USER'
	multipass exec $(ROCK_DEV) -- bash -c 'sudo snap disable docker && sudo snap enable docker'

.PHONY: pack
pack:
	multipass exec $(ROCK_DEV) -- bash -c 'cd $(REPO_FOLDER) && rockcraft pack'

.PHONY: run
run:
	multipass exec $(ROCK_DEV) -- bash -c 'cd $(REPO_FOLDER) &&\
		sudo skopeo --insecure-policy copy oci-archive:charmed-superset-rock_$(ROCK_VERSION)-$(UBUNTU_VER)-edge_amd64.rock docker-daemon:charmed-superset-rock:$(ROCK_VERSION)'
	multipass exec $(ROCK_DEV) -- bash -c "cd $(REPO_FOLDER) &&\
	docker run -d --name $(DOCKER_NAME) -p $(DOCKER_PORT):$(DOCKER_PORT) charmed-superset-rock:$(ROCK_VERSION) --args $(DOCKER_ARGS)"