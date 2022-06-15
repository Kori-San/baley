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
