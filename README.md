# Baley: An AWX Utilitary Tool
An easy to use command line used for AWX's installation and maintenance.

# What is Baley ?
Baley is a command line tool used for an easy installation and / or maintenance for [AWX](https://github.com/ansible/awx#readme)'s Docker Installation.

It is providing a large quantity of commands and settings to customize your AWX installation without making it too complicated.

ie. You can change the default ports of AWX's Web UI to match your preferences or you can change your default dir to install AWX wherever you want.

Baley also offer you a stable AWX installation using persistent volume for PostgreSQL's DB and Redis's Volume, which let you clean your AWX's Environnement without deleting all your data.

# How to install Baley ?
- First you'll need to clone this repo: ```$ git clone https://github.com/Kori-San/baley.git```
- Then cd into the repo and install Baley (You can run make without sudo): ```$ cd baley/ && sudo make install```
- Once the previous task is finished you can configure baley: ```$ baley config```
- You can finally use Baley! You can seek help using: ```$ baley help```

# How to simply install AWX with Baley ?
- First you need to [install Baley](https://github.com/Kori-San/baley/blob/main/README.md#how-to-install-baley-).
- Afterwards you should clone AWX's repo using: ```$ baley clone```
- When the repo is cloned you can begin the build: ```$ baley build```
- After the build you can deploy your AWX's environnement: ```$ baley deploy```
- Baley will show the URL for both http and https.
- After the build you can begin the build of the AWX's Web UI ```$ baley build-ui```
- Enjoy!

# Which commands can I use ?
    $ baley bash [OPTIONNAL DOCKER]        # Begin a bash session on ${main_docker} or given argument.
    $ baley build                          # Build all images needed by AWX.
    $ baley build-ui                       # Build / Rebuild AWX's User Interface.
    $ baley certs PUBLIC_CERT PRIVATE_KEY  # Copy both arguments as 'nginx.crt' and 'nginx.key' on ${main_docker}.
    $ baley clean                          # Clean all images.
    $ baley clone                          # Clone AWX v.${awx_version} from ${awx_git}.
    $ baley config                         # Open config file of Baley.
    $ baley deploy                         # Deploy or Re-Deploy AWX Cluster.
    $ baley edit [ls]                      # Edit docker-compose.yml.j2 while creating a backup file or list backup files.
    $ baley fix  [ISSUE]                   # Apply an automated fix for a know issue.
      ├─── nginx                            ~ Fix Unreachable Web UI caused by nginx service not launching.
      ├─── markupsafe                       ~ Fix Web UI being reachable but not usable even after build.
      └─── config                           ~ Fix error when loading docker config file.
    $ baley help                           # Display help without error.
    $ baley ls                             # Display list of awx-related running dockers.
    $ baley kill [OPTIONNAL DOCKER]        # Kill gracefully all AWX-related docker or given argument.
    $ baley logs [OPTIONNAL DOCKER]        # Display logs of ${main_docker} or given argument.
    $ baley network                        # Display network information about AWX cluster.
    $ baley pkg                            # Install and Upgrade all dependencies.
    $ baley ports http=NUM | https=NUM     # Change HTTP and/or HTTPS ports.

# Dependencies for Baley
- make
- docker
