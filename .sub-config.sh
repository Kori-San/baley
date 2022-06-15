#!/bin/bash

##############
# Init

if [ -z $SUDO_USER ]; then # If the user is not root, we set home to normal home
    home="$HOME"
else # If the user is sudo, then the home directory is /home/$SUDO_USER
    home="/home/$SUDO_USER"
fi

# -> Setting up variables for the script.
conf_path="${home}/.config/baley/baley.conf"
bash_completion_dir="/etc/bash_completion.d"
paste_default_conf="true"
missing_var="false"

##############
# Functions

# -> The below code is a function that prints an error message to the standard error stream.
error_print(){
    >&2 echo "config:" "${1}"
}

# -> A function that prints an error message to the standard error stream.
var_missing(){
    error_print "${1}"
    missing_var="true"
}

# -> Checking if the variable is set in the config file.
var_check(){
    grep "^${1}=" "${conf_path}" > /dev/null 2>&1 || var_missing "${1} is not set in ${conf_path}"
}

##############
# Main

# -> This is checking if the config file exists. If it does, it checks if all the variables are set. If
#    they are, it sets paste_default_conf to false.
if [ -f "${conf_path}" ]; then
    var_check "awx_root_dir"
    var_check "awx_clone_dir"
    var_check "awxdb_root_dir"
    var_check "awxdb_dir"
    var_check "awx_version"
    var_check "awx_git"
    var_check "http"
    var_check "https"
    var_check "waiting_interval"
    var_check "save"
    var_check "main_docker"
    var_check "working_dir"
    var_check "awx_path"
    var_check "awxdb_path"
    grep '^save="$(( save - 1 ))"' "${conf_path}" > /dev/null 2>&1 || var_missing "'save' adjustment not found in ${conf_path}"
    var_check "argument"
    var_check "ps_filter"
    var_check "docker_compose_folder"
    var_check "docker_compose_path"
    var_check "docker_volume_settings"
    if [ "$missing_var" = "false" ]; then
        echo "config: Config file ${conf_path} is valid."
        paste_default_conf="false"
    fi
fi

# -> If the config file does not exist, it creates it.
if [ "${paste_default_conf}" = "true" ]; then
    mkdir -p "$(dirname "${conf_path}")"
    cp ".baley_default.conf" "${conf_path}" && echo "config: Default configuration pasted."
fi

# -> Check if user is root
if [ "$(id -u)" -eq 0 ]; then
    # ~> Creating the directory if it does not exist.
    mkdir -p "${bash_completion_dir}"
    # ~> Copying the bash completion script to the bash completion directory.
    cp -p ".baley_completion" "${bash_completion_dir}/baley_completion"
    # ~> Setting the permissions to 644.
    chmod 644 "${bash_completion_dir}/baley_completion"
    echo "config: Apply Bash's completion by running: '$ source ~/.bashrc'"
    echo "        otherwise it will apply to your next bash session"
else
    # ~> If the user is not root, we print an error message.
    error_print "/!\ You need to be root to paste the bash completion script."
fi
