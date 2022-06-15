#!/bin/bash

############################################################################
## Baley - An AWX Utilitary Tool            ________________/  / Jun 2022 ##
## └─(v.1.0)                               / By Aymen Ezzayer / Kori-San  ##
############################################################################

##############
# Init

conf_path="${HOME}/.config/baley/baley.conf"
# ↳ Path to config file - Default: ~/.config/baley/baley.conf

source "${conf_path}" || error_print "Config file not found"
# ↳ Source config file

if [ -z "${EDITOR}" ]; then
    EDITOR="vim"
fi

##############
# Functions

# -> A function that waits for a certain amount of time.
waiting()
{
    if [ "${#}" -ne "1" ]; then
        printf "Not wainting\n"
        exit 1;
    fi
    wtime="${1}" # Wait Time
    for i in $(seq "1" "${wtime}"); do
        if [ "$(( i % 2))" -eq "0" ]; then
            printf "Waiting %s second(s)     \r" "$(( wtime - i ))"
        else
            printf "Waiting %s second(s)     \r" "$(( wtime - i ))"
        fi
        sleep 1
    done
    printf "\n"
    return 0
}

# -> The func checks if a package is installed. If it is not installed, it will install it.
pkg_check()
{
    if dpkg -s "${1}" 1> /dev/null ; then
        echo " ~ '$ ${1}' found, skipping install..."
    else
        echo " ~ '$ ${1}' not found, installing ${1}..."
        apt-get install -q -y "${1}" 1> /dev/null
    fi
}

# -> The below code is a function that prints an error message to the standard error stream.
error_print()
{
    >&2 echo "baley:" "${1}"
    exit 1
}

wrong_behaviour()
{
    >&2 echo "baley:" "${1}"
    Help
    exit 1
}

# -> A function that displays the help menu.
Help()
{
    echo -e "--\nCommands:"
    echo -e "$ baley bash [OPTIONNAL DOCKER]        # Begin a bash session on ${main_docker} or given argument."
    echo -e "$ baley build                          # Build all images needed by AWX."
    echo -e "$ baley build-ui                       # Build / Rebuild AWX's User Interface."
    echo -e "$ baley certs PUBLIC_CERT PRIVATE_KEY  # Copy both arguments as 'nginx.crt' and 'nginx.key' on ${main_docker}."
    echo -e "$ baley clean                          # Clean all images."
    echo -e "$ baley clone                          # Clone AWX v.${awx_version} from ${awx_git}."
    echo -e "$ baley config                         # Open config file of Baley."
    echo -e "$ baley deploy                         # Deploy or Re-Deploy AWX Cluster."
    echo -e "$ baley edit [ls]                      # Edit docker-compose.yml.j2 while creating a backup file or list backup files."
    echo -e "$ baley fix [ISSUE]                    # Apply an automated fix for a know issue."
    echo -e "  ├─── nginx                            ~ Fix Unreachable Web UI caused by nginx service not launching."
    echo -e "  ├─── markupsafe                       ~ Fix Web UI being reachable but not usable even after build."
    echo -e "  └─── config                           ~ Fix error when loading docker config file."
    echo -e "$ baley help                           # Display help without error."
    echo -e "$ baley ls                             # Display list of awx-related running dockers."
    echo -e "$ baley kill [OPTIONNAL DOCKER]        # Kill gracefully all AWX-related docker or given argument."
    echo -e "$ baley logs [OPTIONNAL DOCKER]        # Display logs of ${main_docker} or given argument."
    echo -e "$ baley network                        # Display network information about AWX cluster."
    echo -e "$ baley pkg                            # Install and Upgrade all dependencies."
    echo -e "$ baley ports http=NUM | https=NUM     # Change HTTP and/or HTTPS ports."
}

##############
# Main

# -> Checking if the argument is "bash" and if it is, it will enter a docker container.
if [ "${argument,,}" == "bash" ]; then
    # ~> If there is 1 argument it will enter the main docker container.
    if [ "${#}" -eq "1" ]; then
        echo "Entering ${main_docker} /bin/bash"
        docker exec -it "${main_docker}" /bin/bash || error_print "Failed to enter ${main_docker}"
    # ~> If there is 2 arguments it will enter the given docker container.
    elif  [ "${#}" -eq "2" ]; then
        echo "Entering ${2} /bin/bash"
        docker exec -it "${2}" /bin/bash || error_print "Failed to enter ${2}"
    # ~> If there is more than 2 arguments it will return an error and display the help.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "build" and if it is, it will build all images needed by AWX.
elif [ "${argument,,}" == "build" ]; then
    # ~> If there is no additional argument it will build all images needed by AWX.
    if [ "${#}" -eq "1" ]; then
        # ~> It's changing the ports of the docker-compose.yml.j2 file.
        echo "Changing Ports 8013 -> ${http} & 8043 -> ${https}"
        sed -i -e "s/[0-9]*:8013/${http}:8013/g" "${docker_compose_path}" || error_print "Failed to change HTTP Port"
        sed -i -e "s/[0-9]*:8043/${https}:8043/g" "${docker_compose_path}" || error_print "Failed to change HTTPS Port"
        # ~> It's creating the database directory and changing the database's path.
        echo "Creating Database directory and changing Database's path"
        mkdir -p "${awxdb_path}/postgre" "${awxdb_path}/redis" || error_print "Failed to create database directory"
        # ~> Making PostgreDB Volume persistent in docker-compose file.
        dbname="tools_awx_db"
        sed -i -e "s@name: ${dbname}@name: ${dbname}${docker_volume_settings}'${awxdb_path}/postgre'@g" "${docker_compose_path}" || error_print "Failed to change PostgreDB Volume"
        # ~> Making Redis Volume persistent in docker-compose file.
        dbname="tools_redis_socket_{{ container_postfix }}"
        sed -i -e "s@name: ${dbname}@name: ${dbname}${docker_volume_settings}'${awxdb_path}/redis'@g" "${docker_compose_path}" || error_print "Failed to change Redis Volume"
        # ~> It's going into the cloned repo directory.
        cd "${awx_path}" || error_print "Could not enter ${awx_path} folder"
        echo "Building all images needed by AWX"
        make "docker-compose-build" || error_print "Could not build AWX"
        echo "You may deploy AWX now by running '$ baley deploy'"
    # ~> If there is more than 1 argument it will return an error and display the help.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is build-ui and if it is, it is running the command make clean-ui ui-devel
elif [ "${argument,,}" == "build-ui" ]; then
    # ~> If there is only 1 argument it will execute the command "docker exec make clean-ui ui-devel".
    if [ "${#}" -eq "1" ]; then
        echo -e "Cleaning and (re)creating UI from ${main_docker}"
        docker exec "${main_docker}" make clean-ui ui-devel || error_print "Failed to clean and (re)create UI"
    # ~> If there is more than 1 argument it will return an error and display the help.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "certs" and if it is, it is copying them to the docker container.
elif [ "${argument,,}" == "certs" ]; then
    # ~> Checking if the number of arguments is equal to 3.
    if [ "${#}" -eq "3" ]; then
        # ~> If it is, it will check if the second and third arguments are files.
        if [ -f "${2}" ] && [ -f "${3}" ]; then
            # ~> If they are, it will copy the files to the docker container.
            docker cp "${2}" "${main_docker}:/etc/nginx/nginx.crt" || error_print "Failed to copy ${2} to ${main_docker}"
            docker cp "${3}" "${main_docker}:/etc/nginx/nginx.key" || error_print "Failed to copy ${3} to ${main_docker}"
            docker exec -it "${2}" nginx -s stop || error_print "Failed to stop nginx"
        # ~> If they are not, it will return an error and display the help.
        else
            wrong_behaviour "${2} or ${3} does not exist"
        fi
    # ~> If the number of arguments is not equal to 3, it will return an error and display the help.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> checking if the argument is "clean" and if it is, it is cleaning the docker container.
elif [ "${argument,,}" == "clean" ]; then
    # ~> If there is no additional argument it will clean the docker container.
    if [ "${#}" -eq "1" ]; then
        baley kill || error_print "Failed to kill AWX-Related Containers"
        docker system prune --filter "${ps_filter}" -af || error_print "Failed to clean images"
        echo -e "AWX's environment is clean.\nYou may build and deploy AWX again."
    # ~> If there is more than 1 argument it will return an error and display the help.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "clone" and if it is, it is cloning the awx-repository.
elif [ "${argument,,}" == "clone" ]; then
    # ~> Checking if the number of arguments is equal to 1.
    if [ "${#}" -eq "1" ]; then
        # ~> If it is, it will clone the awx-repository.
        echo -e "Cloning AWX version ${awx_version} from ${awx_git}"
        waiting "${waiting_interval}"
        git clone -b "${awx_version}" "${awx_git}" "${awx_path}" || error_print "Failed to clone AWX"
        echo -e "AWX is cloned.\nYou may build AWX now by running '$ baley build'"
    # ~> If the number of arguments is not equal to 1, it will return an error and display the help.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "config" and if it is, it will open baley's config file with the default editor.
elif [ "${argument,,}" == "config" ]; then
    # ~> Checking if the number of arguments is equal to 1. If it is, it will open baley's config file with the default editor.
    conf_dir=$(dirname "${conf_path}")
    if [ "${#}" -eq "1" ]; then
        # ~> Rotate Backup files.
        ls -a "${conf_dir}" | grep ".conf" | sort | head -n -"$save" |  sed "s@^@${conf_dir}/@g" | xargs -rd '\n' rm -fr
        # ~> Create Backup file.
        backup_timestamp=$(date '+%H:%M:%S-%d_%m_%Y')
        cp "${docker_compose_path}" "${conf_dir}/baley.${backup_timestamp}.conf" || error_print "Failed to create backup file"
        "${EDITOR}" "${conf_path}"
        echo -e "Backup file created in ${conf_dir}/baley.${backup_timestamp}.conf"
    # ~> If there is 2 arguments and the second one is ls it will list backup files.
    elif  [ "${#}" -eq "2" ]; then
        if [ "${2,,}" == "ls" ]; then
            echo "Most Recent Backup first:"
            ls -a "${conf_dir}" | grep ".conf" | sort |  sed "s@^@${conf_dir}/@g"
        else
            wrong_behaviour "Invalid argument"
        fi
    # ~> If the number of arguments is not equal to 1, it will print an error message.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is deploy, if it is, it will deploy the docker-compose environment.
elif [ "${argument,,}" == "deploy" ]; then
    # If $(PWD) is not the same as the awx_path we go to awx_path.
    if [ "$(pwd)" != "${awx_path}" ]; then
        cd "${awx_path}" || error_print "Could not enter ${awx_path} folder"
    fi
    # ~> If there is only 1 argument it will execute the command "docker-compose up -d".
    if [ "${#}" -eq "1" ]; then
        echo -e "Deploying docker-compose environment..."
        make "docker-compose" COMPOSE_UP_OPTS="-d" || error_print "Failed to deploy docker-compose environment"
        awx_no_ssl=$(baley network | grep 8013 | grep -zoP "localhost:[0-9]+" | tr -d '\0')
        awx_ssl=$(baley network | grep 8043 | grep -zoP "localhost:[0-9]+" | tr -d '\0' )
        echo -e "Deployment complete."
        echo -e "You can Build Web UI by running '$ baley build-ui'"
        echo -e "Access AWX at http://${awx_no_ssl} or https://${awx_ssl}"
    # ~> If there is more than 1 argument it will return an error and display the help.
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "edit" and if it is, open it in a text editor.
elif [ "${argument,,}" == "edit" ]; then
    # ~> Checking if the docker-compose.yml.j2 file exists. If it does, it is checking if there is one or two arguments.
    if [ ! -f "${docker_compose_path}" ]; then
        error_print "docker-compose.yml.j2 path is invalid, please check your config file using '$ baley config'"
    else
        # ~> If there is one argument, it is rotating the backup files and creating a new backup file and open it in a text editor.
        if [ "${#}" -eq "1" ]; then
            # ~> Rotate Backup
            ls -a "${docker_compose_folder}" | grep ".docker-compose" | sort | head -n -"$save" |  sed "s@^@${docker_compose_folder}/@g" | xargs -rd '\n' rm -fr
            # ~> Create Backup
            backup_timestamp=$(date '+%H:%M:%S-%d_%m_%Y')
            cp "${docker_compose_path}" "${docker_compose_folder}/.docker-compose.${backup_timestamp}.yml.j2"
            "${EDITOR}" "${docker_compose_path}"
            echo -e "Backup file created in ${docker_compose_folder}/.docker-compose.${backup_timestamp}.yml.j2"
        # ~> If there is two arguments, it is checking if the second argument is "ls". If it is, it is listing the backup files.
        elif  [ "${#}" -eq "2" ]; then
            if [ "${2,,}" == "ls" ]; then
                echo "Most Recent Backup first:"
                ls -a "${docker_compose_folder}" | grep ".docker-compose" | sort -r |  sed "s@^@${docker_compose_folder}/@g"
            else
                wrong_behaviour "Invalid argument"
            fi
        # ~> If there is more than two arguments, it is printing an error message and exiting.
        else
            wrong_behaviour "Invalid number of arguments"
        fi
    fi

# -> Checking if the argument is "fix" and check the second argument and it is executing the corresponding command.
elif [ "${argument,,}" == "fix" ]; then
    # ~> Checking if the number of arguments is not equal to 2.
    if [ "${#}" -ne "2" ]; then
        wrong_behaviour "Invalid number of arguments"
    # ~> Checking if the 2nd argument is 'nginx'.
    elif [ "${2,,}" == "nginx" ]; then
        docker exec "${main_docker}" useradd -s /sbin/nologin -M nginx -g nginx
        docker exec "${main_docker}" nginx
    # ~> Checking if the 2nd argument is 'markupsafe'.
    elif [ "${2,,}" == "markupsafe" ]; then
        docker exec "${main_docker}" pip uninstall -y 'markupsafe'
        docker exec "${main_docker}" pip install 'markupsafe'=='2.0.1'
    # ~> Checking if the 2nd argument is 'config'.
    elif [ "${2,,}" == "config" ]; then
        chown "$USER":"$USER" /home/"$USER"/.docker -R
        chmod g+rwx "/home/$USER/.docker" -R
    # ~> If the argument is not recognized, it is printing an error message and exiting.
    else
        wrong_behaviour "Invalid argument"
    fi
    printf "\n/!\\ It is recommanded to redeploy !\n\n"

# -> Checking if the argument is equal to "help" in lowercase.
elif [ "${argument,,}" == "help" ]; then
    # ~> Display help without error
    Help

# -> Checking if the argument is "ls" and if it is, it is running a docker command to list all the
#    running dockers.
elif [ "${argument,,}" == "ls" ]; then
    # ~> Display list of awx-related running dockers
    if [ "${#}" -eq "1" ]; then
        docker ps --filter "${ps_filter}" --format "- '{{ .Names }}' \trunning since {{ .RunningFor }}\twith ID: {{ .ID }}" \
        | sed "s/ ago//g"
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "kill" and if it is, it is stopping the docker containers that match the ps_filter
elif [ "${argument,,}" == "kill" ]; then
    # ~> Checking if there is one or two arguments. If there is one argument, it is stopping all
    #    the docker containers that match the ps_filter. If there is two arguments, it is stopping
    #    the docker container that matches the second argument.
    if [ "${#}" -eq "1" ]; then
        if [ -z $(docker ps --filter "${ps_filter}" -q) ]; then
            echo -e "No docker containers found"
        else
            docker stop $(docker ps --filter "${ps_filter}" -q) || error_print "Failed to stop docker containers"
        fi
    elif  [ "${#}" -eq "2" ]; then
        docker stop "${2}" || error_print "Failed to stop ${2}"
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is logs and if it is, it will run docker logs
elif [ "${argument,,}" == "logs" ]; then
    # ~> Checking if the number of arguments is 1 or 2. If it is 1, it will display the logs of the main
    #    docker. If it is 2, it will display the logs of the second argument.
    if [ "${#}" -eq "1" ]; then
        docker logs -f "${main_docker}" || error_print "Failed to get logs from ${main_docker}"
    elif  [ "${#}" -eq "2" ]; then
        docker logs -f "${2}" || error_print "Failed to get logs for ${2}"
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "network" and if it is, it is displaying the network information about
#    the AWX cluster.
elif [ "${argument,,}" == "network" ]; then
    # ~> Checking if the number of arguments is equal to 1. If it is, it will run the docker ps command with
    #    the filter and format options. The sed commands are used to format the output. if the number of arguments
    #    is less than or equal to 1. If it is, it will print an error message and call the help function.
    if [ "${#}" -eq "1" ]; then
        docker ps --filter "${ps_filter}" --format "[{{ .Names }}]\nNetwork: {{ .Networks }}\nPorts:\t - {{ .Ports }}\n" \
        | sed "s/,/\n\t -/g" \
        | sed "s/:::/localhost:/g" \
        | sed "s/->/ -> docker:/g"
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is "pkg" and if it is, it will install and upgrade all dependencies.
elif [ "${argument,,}" == "pkg" ]; then
    # ~> Check if the user is root
    if [ "$(id -u)" == "0" ]; then
        # ~> Install and Upgrade all dependencies
        if [ "${#}" -eq "1" ]; then
            # ~> Updating the apt-get repository.
            echo "Checking dependencies"
            apt-get update -y > /dev/null
            # ~> Checking if the packages are installed.
            pkgs=("python3.9" "python3-pip" "docker-compose" "docker.io" "ansible" "openssl" "pass" "gnupg2" "gzip" "conntrack")
            for package in ${pkgs[@]}; do
                pkg_check "${package}"
            done
            # ~> Upgrading the dependencies.
            echo -e "\nUpgrading dependencies"
            apt-get upgrade -y > /dev/null
        else
            wrong_behaviour "Invalid number of arguments"
        fi
    else
        error_print "You must be root to manage packages"
    fi

# -> Checking if the argument is "ports" and if it is, it is changing the ports.
elif [ "${argument,,}" == "ports" ]; then
    # ~> Checking if the argument is "ports" and if it is, it is checking if the number of arguments is less
    #    than or equal to 3. If it is, it is checking if the arguments are valid. If they are, it is changing
    #    the ports.
    if [ "${#}" -le "3" ]; then
        if echo "${2}" | grep -zoP "((http[s]?=[0-9]+)|())" 1> /dev/null && echo "${3}" grep -zoP "((http[s]?=[0-9]+)|())" 1> /dev/null; then
            count=$(echo -e "${2}\n${3}" \
            | sed "s/http=[0-9]*/http/g" \
            | sed "s/https=[0-9]*/https/g" \
            |  uniq -c | sort -r | head -n 1 \
            |  sed "s/ [a-zA-Z]*//g")
            if [ "$count" = "1" ]; then
                # ~> Taking the second and third arguments and searching for the string "http=" and then removing the
                #    "http=" and returning the number.
                http=$(echo "${2} ${3}" \
                | grep -zoP -m 1 "(http=[0-9]*)" \
                | tr -d '\0' \
                | sed "s/http=//g")
                # ~> Using grep to find the first instance of the string "https=", and then it is removing the "https="
                #    part of the string.
                https=$(echo "${2} ${3}" \
                | grep -zoP -m 1 "(https=[0-9]*)" \
                | tr -d '\0'\
                | sed "s/https=//g")
                # ~> Checking if the http and https ports are the same.
                if [ "${http}" == "${https}" ]; then
                    error_print "The ports are the same"
                fi
                # ~> Checking if the http and https ports are empty.
                if [ -z "${http}" ] || [ -z "${https}" ]; then
                    error_print "Ports are empty"
                fi
                # ~> Changing the port 8013 to the port that the user has entered.
                if [ -n "${http}" ]; then
                    printf "Changing Port 8013 -> %s\n" "${http}"
                    sed -i -e "s/[0-9]*:8013/${http}:8013/g" "${docker_compose_path}" || exit 1
                fi
                # ~> Changing the port 8043 to the port that the user has entered.
                if [ -n "${https}" ]; then
                    printf "Changing Port 8043 -> %s\n" "${https}"
                    sed -i -e "s/[0-9]*:8043/${https}:8043/g" "${docker_compose_path}" || exit 1
                fi
                printf "Done!\nYou should Re-Deploy to apply changes.\n"
            else
                wrong_behaviour "Don't use same arguments twice"
            fi
        else
            wrong_behaviour "Invalid arguments"
        fi
    else
        wrong_behaviour "Invalid number of arguments"
    fi

# -> Checking if the argument is not recognized
else
    # ~> Display the help message with an error.
    if [ "${#}" -eq "0" ]; then
        wrong_behaviour "USAGE: $ baley COMMAND [ARGS]"
    else
        wrong_behaviour "Invalid arguments"
    fi
fi

# -> Going back to Original Directory
if [ "$(pwd)" != "${working_dir}" ]; then
    cd "${working_dir}" || error_print "Failed to go back to original directory"
fi

# -> Exiting the script.
exit 0
