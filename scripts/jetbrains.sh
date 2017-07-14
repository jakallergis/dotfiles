#!/bin/bash

DIM='\033[2m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # NO Color

echo
echo -e "${BLUE}Updating Packages and installing prerequisites...${NC}"

apt-get -qq update
apt-get -qq install mc htop git unzip wget curl -y > /dev/null 2>&1

echo
echo -e "${ORANGE}====================================================="
echo -e "${BLUE}                     WELCOME"
echo -e "${ORANGE}=====================================================${NC}"
echo
echo -e "${ORANGE}Hub"
echo -e "${NC}${DIM}download https://www.jetbrains.com/hub/download/"
echo -e "read instruction https://www.jetbrains.com/hub/help/1.0/Installing-Hub-with-Zip-Distribution.html"
echo -e "install into /usr/jetbrains/youtrack/"
echo -e "${ORANGE}=====================================${NC}"
echo
echo -e "${ORANGE}YouTrack"
echo -e "${NC}${DIM}download https://www.jetbrains.com/youtrack/download/get_youtrack.html"
echo -e "read instruction https://confluence.jetbrains.com/display/YTD65/Installing+YouTrack+with+ZIP+Distribution#InstallingYouTrackwithZIPDistribution-InstallingNewYouTrackServer"
echo -e "install into /usr/jetbrains/youtrack/"
echo -e "${ORANGE}=====================================${NC}"
echo
echo -e "${ORANGE}Upsource"
echo -e "${NC}${DIM}download https://www.jetbrains.com/upsource/download/"
echo -e "read the first https://www.jetbrains.com/upsource/help/2.0/prerequisites.html"
echo -e "install into /usr/jetbrains/upsource/"
echo -e "${ORANGE}=====================================${NC}"
echo
echo "In order to continue installing we need to set a few properties for nginx..."
echo

base_domain="http://localhost.local"
hub_domain="http://localhost.local"
hub_port=8080
yt_domain="http://localhost.local"
yt_port=8081
us_domain="http://localhost.local"
us_port=8082
cron_email=""

code=`lsb_release -a | grep Codename | sed 's/[[:space:]]//g' | cut -f2 -d:`

echo
echo -e "${ORANGE}Debian codename: ${RED}${code}${NC}"
echo

mkdir -p /var/tmp
pushd /var/tmp > /dev/null 2>&1

ask_param () {
    if [ "$1" == "base_domain" ]; then
        echo -e "${BLUE}Base domain url: ${NC}${DIM}(Default: http://localhost) ${NC}"
        read base_domain
    fi

    if [ "$1" == "hub_domain" ]; then
        echo -e "${BLUE}Hub domain url: ${NC}${DIM}(Default: http://localhost) ${NC}"
        read hub_domain
    fi

    if [ "$1" == "hub_port" ]; then
        echo -e "${BLUE}Hub port: ${NC}${DIM}(Default: 8080): ${NC}"
        read hub_port
    fi

    if [ "$1" == "yt_domain" ]; then
        echo -e "${BLUE}Youtrack domain url: ${NC}${DIM}(Default: http://localhost) ${NC}"
        read yt_domain
    fi

    if [ "$1" == "yt_port" ]; then
        echo -e "${BLUE}Youtrack port: ${NC}${DIM}(Default: 8081): ${NC}"
        read yt_port
    fi

    if [ "$1" == "us_domain" ]; then
        echo -e "${BLUE}Upsource domain url: ${NC}${DIM}(Default: http://localhost) ${NC}"
        read us_domain
    fi

    if [ "$1" == "us_port" ]; then
        echo -e "${BLUE}Upsource port: ${NC}${DIM}(Default: 8082) ${NC}"
        read us_port
    fi

    if [ "$1" == "cron_email" ]; then
        echo -e "${BLUE}Cron email: ${NC}"
        read cron_email
    fi
}

check_param() {
    if [ "$2" == "" ]; then
        if [ "$1" == "base_domain" ]; then base_domain="http://localhost.local" ;fi
        if [ "$1" == "hub_domain" ]; then hub_domain="http://localhost.local" ;fi
        if [ "$1" == "hub_port" ]; then hub_port=8080 ;fi
        if [ "$1" == "yt_domain" ]; then yt_domain="http://localhost.local" ;fi
        if [ "$1" == "yt_port" ]; then yt_port=8081 ;fi
        if [ "$1" == "us_domain" ]; then us_domain="http://localhost.local" ;fi
        if [ "$1" == "us_port" ]; then us_port=8082 ;fi
    fi
}

print_params() {
	echo -e "${ORANGE}=================${NC}"
	echo
	echo -e "${NC}${DIM}Base domain url: ${ORANGE}${base_domain}${NC}"
	echo -e "${NC}${DIM}Hub domain url: ${ORANGE}${hub_domain}${NC}"
	echo -e "${NC}${DIM}hub port: ${ORANGE}${hub_port}${NC}"
	echo -e "${NC}${DIM}Youtrack domain url: ${ORANGE}${yt_domain}${NC}"
	echo -e "${NC}${DIM}Youtrack port: ${ORANGE}${yt_port}${NC}"
	echo -e "${NC}${DIM}Upsource domain url: ${ORANGE}${us_domain}${NC}"
	echo -e "${NC}${DIM}Upsource port: ${ORANGE}${us_port}${NC}"
	echo -e "${NC}${DIM}Cron email: ${ORANGE}${cron_email}${NC}"
	echo
	echo -e "${ORANGE}=================${NC}"
}

install_java() {
    echo -e "${BLUE}Version of openJDK JRE to Install ${NC}${DIM}(Default: openjdk-${ORANGE}7${NC}${DIM}-jre) ${ORANGE}[7/8]${BLUE}:${NC}"
    read version_to_install

    if [ "$version_to_install" == 8 ]; then
        version_to_install=8
    else
        version_to_install=7
    fi

    echo
    echo -e "${ORANGE}Installing openJDK ${version_to_install} JRE...${NC}"

    add-apt-repository ppa:openjdk-r/ppa -y > /dev/null 2>&1
    apt-get -qq update > /dev/null 2>&1
    apt-get -qq install openjdk-${version_to_install}-jre -y > /dev/null 2>&1

    echo
    echo -e "${NC}${DIM}Java was successfully Installed${NC}"
    echo
}

download_services() {
    mkdir -p /usr/jetbrains/youtrack /usr/jetbrains/hub /usr/jetbrains/upsource

    echo -e "${ORANGE}Downloading Hub...${NC}"
    wget -qq https://download.jetbrains.com/hub/2017.2/hub-ring-bundle-2017.2.6307.zip -O /usr/jetbrains/hub/arch.zip
    echo -e "${ORANGE}Downloading Youtrack...${NC}"
    wget -qq https://download.jetbrains.com/charisma/youtrack-2017.2.34480.zip -O /usr/jetbrains/youtrack/arch.zip
    echo -e "${ORANGE}Downloading Upsource...${NC}"
    wget -qq https://download.jetbrains.com/upsource/upsource-2017.2.2057.zip -O /usr/jetbrains/upsource/arch.zip

    pushd /usr/jetbrains/hub > /dev/null 2>&1
    echo -e "${NC}${DIM}Exctracting Hub...${NC}"
    unzip -qq arch.zip
    mv hub-ring-bundle-2017.2.6307/* .
    rm -rf hub-ring-bundle-2017.2.6307
    chmod +x -R ../hub/
    popd > /dev/null 2>&1

    pushd /usr/jetbrains/youtrack > /dev/null 2>&1
    echo -e "${NC}${DIM}Exctracting Youtrack...${NC}"
    unzip -qq arch.zip
    mv youtrack-2017.2.34480/* .
    rm -rf youtrack-2017.2.34480
    chmod +x -R ../youtrack/
    popd > /dev/null 2>&1

    pushd /usr/jetbrains/upsource > /dev/null 2>&1
    echo -e "${NC}${DIM}Exctracting Upsource...${NC}"
    unzip -qq arch.zip
    mv upsource-2017.2.2057/* .
    rm -rf upsource-2017.2.2057
    chmod +x -R ../upsource/
    popd > /dev/null 2>&1
    popd > /dev/null 2>&1
}

make_initd() {
    echo -e "${ORANGE}Making init.d for $1...${NC}"
    wget -qq "https://raw.githubusercontent.com/jakallergis/dotfiles/master/scripts/init.d/${1}" -O /etc/init.d/$1
    chmod +x /etc/init.d/$1

    echo -e "${NC}${DIM}Updating default service script for $1...${NC}"
    update-rc.d $1 remove > /dev/null 2>&1
    update-rc.d $1 defaults > /dev/null 2>&1
    if [ "$1" != "hub" ]; then
        echo -e "${NC}${DIM}Disabling services scripts for $1...${NC}"
        update-rc.d $1 disable > /dev/null 2>&1
    fi
}

install_nginx() {
    echo -e "${ORANGE}Configure nginx...${NC}"
    apt-get -qq install -t ${code}-backports nginx -y > /dev/null 2>&1

    cat >./default<<EOF
server {
	listen 80;
	listen [::]:80;
	server_name ${yt_domain};
	server_tokens off;

	location / {
		proxy_set_header X-Forwarded-Host \$http_host;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_http_version 1.1;

		proxy_pass http://localhost:${yt_port}/;
	}
}
server {
	listen 80;
	listen [::]:80;
	server_name ${us_domain};
	server_tokens off;

	location / {
		proxy_set_header X-Forwarded-Host \$http_host;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_http_version 1.1;

		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection "upgrade";

		proxy_pass http://localhost:${us_port}/;
	}
}
server {
	listen 80;
	listen [::]:80;
	server_name ${hub_domain};
	server_tokens off;

	location / {
		proxy_set_header X-Forwarded-Host \$http_host;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_http_version 1.1;

		proxy_pass http://localhost:${hub_port}/;
	}
}
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	root /var/www/html;
	index index.html index.htm index.nginx-debian.html;
	server_name ${base_domain};
	server_tokens off;

	location / {
		try_files \$uri \$uri/ =404;
	}
}
EOF

    mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
    cp -f default /etc/nginx/sites-available/default

    service nginx restart
}

install_cronjob() {
    mkdir -p /root/crons

    cat >/root/crons/jetbrains<<EOF
#!/bin/bash
status=404
while [ \$status -eq 404 ]; do
  echo "wait hub..."
  sleep 60
  status=\`curl -s -o /dev/null -w "%{http_code}" http://${hub_domain}/hub\`
  echo "hub status \$status"
done
service youtrack start
service upsource start
exit 0
EOF

    chmod +x /root/crons/jetbrains

    echo "MAILTO=$cron_email" > /tmp/cron_
    echo "" >> /tmp/cron_
    echo "@reboot /root/crons/jetbrains" > /tmp/cron_
    crontab /tmp/cron_
}

config_services() {
    echo -e "${ORANGE}Configuring Hub...${NC}${DIM}"
    /usr/jetbrains/hub/bin/hub.sh configure --listen-port ${hub_port} --base-url http://${hub_domain}

    echo -e "${NC}"
    echo -e "${ORANGE}Configuring Youtrack...${NC}${DIM}"
    /usr/jetbrains/youtrack/bin/youtrack.sh configure --listen-port ${yt_port} --base-url http://${yt_domain}

    echo -e "${NC}"
    echo -e "${ORANGE}Configuring Upsource...${NC}${DIM}"
    /usr/jetbrains/upsource/bin/upsource.sh configure --listen-port ${us_port} --base-url http://${us_domain}

    echo -e "${NC}"

    if [ "$1" == "initd_created" ]; then
        echo -e "${BLUE}Start Hub Service? ${ORANGE}[yes/NO]:${NC}"
        read start_hub
        if [ "$start_hub" != "yes" ]; then echo -e "${NC}${DIM}Skipping Hub Service...${NC}"; else service hub start; fi

        echo -e "${BLUE}Start Youtrack Service? ${ORANGE}[yes/NO]:${NC}"
        read start_youtrack
        if [ "$start_youtrack" != "yes" ]; then echo -e "${NC}${DIM}Skipping Hub Service...${NC}"; else service youtrack start; fi

        echo -e "${BLUE}Start Upsource Service? ${ORANGE}[yes/NO]:${NC}"
        read start_upsource
        if [ "$start_upsource" != "yes" ]; then echo -e "${NC}${DIM}Skipping Hub Service...${NC}"; else service upsource start; fi

        echo
        echo -e "${NC}After manually starting the services the services will be accessible at:${NC}"
        echo -e "${BLUE}Hub: ${ORANGE}${hub_domain}${NC}"
        echo -e "${BLUE}Youtrack: ${ORANGE}${yt_domain}${NC}"
        echo -e "${BLUE}Upsource: ${ORANGE}${us_domain}${NC}"

        echo
        if [ "$start_hub" != "yes" ] || [ "$start_youtrack" != "yes" ] || [ "$start_upsource" != "yes" ]; then
            echo -e "${NC}To start each service run:${NC}"
        fi
        if [ "$start_hub" != "yes" ]; then echo -e "${NC}${DIM}Hub Service: ${ORANGE}service hub start"${NC}; fi
        if [ "$start_youtrack" != "yes" ]; then echo -e "${NC}${DIM}Youtrack Service: ${ORANGE}service youtrack start"${NC}; fi
        if [ "$start_upsource" != "yes" ]; then echo -e "${NC}${DIM}Upsource Service: ${ORANGE}service upsource start"${NC}; fi
    fi
}

config_swapfile() {
    echo -e "${ORANGE}Configuring swapfile...${NC}"
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    swapon -s

    echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab

    cp /usr/jetbrains/hub/conf/hub.jvmoptions.dist /usr/jetbrains/hub/conf/hub.jvmoptions
    echo "-Xmx1g" >> /usr/jetbrains/hub/conf/hub.jvmoptions
    echo "-XX:MaxPermSize=250m" >> /usr/jetbrains/hub/conf/hub.jvmoptions
    echo "-Xmx1024m" >> /usr/jetbrains/hub/conf/hub.jvmoptions
    echo "-Djava.awt.headless=true" >> /usr/jetbrains/hub/conf/hub.jvmoptions
    cp /usr/jetbrains/youtrack/conf/youtrack.jvmoptions.dist /usr/jetbrains/youtrack/conf/youtrack.jvmoptions
    echo "-Xmx1g" >> /usr/jetbrains/youtrack/conf/youtrack.jvmoptions
    echo "-XX:MaxPermSize=250m" >> /usr/jetbrains/youtrack/conf/youtrack.jvmoptions
    echo "-Xmx1024m" >> /usr/jetbrains/youtrack/conf/youtrack.jvmoptions
    echo "-Djava.awt.headless=true" >> /usr/jetbrains/youtrack/conf/youtrack.jvmoptions
    cp /usr/jetbrains/upsource/conf/upsource.jvmoptions.dist /usr/jetbrains/upsource/conf/upsource.jvmoptions
    echo "-Xmx1g" >> /usr/jetbrains/upsource/conf/upsource.jvmoptions
    echo "-XX:MaxPermSize=250m" >> /usr/jetbrains/upsource/conf/upsource.jvmoptions
    echo "-Xmx1024m" >> /usr/jetbrains/upsource/conf/upsource.jvmoptions
    echo "-Djava.awt.headless=true" >> /usr/jetbrains/upsource/conf/upsource.jvmoptions

    echo -e "${NC}${DIM}Swapfile configuration complete.${NC}"
}

echo -e "${BLUE}Skip urls and ports input? ${ORANGE}[yes/NO]:${NC}"
read type

if [ "$type" != "yes" ]; then
  echo -e "${ORANGE}"
  ask_param base_domain
  check_param base_domain ${base_domain}
  ask_param hub_domain
  check_param hub_domain ${hub_domain}
  ask_param hub_port
  check_param hub_port ${hub_port}
  ask_param yt_domain
  check_param yt_domain ${yt_domain}
  ask_param yt_port
  check_param yt_port ${yt_port}
  ask_param us_domain
  check_param us_domain ${us_domain}
  ask_param us_port
  check_param us_port ${us_port}
  ask_param cron_email
  echo -e "${NC}"
fi

print_params

echo -e "${BLUE}Skip installation of OpenJDK? ${ORANGE}[yes/NO]:${NC}"
read type
if [ "$type" != "yes" ]; then install_java; fi

echo -e "${BLUE}Skip Download of Services? ${ORANGE}[yes/NO]:${NC}"
read type
if [ "$type" != "yes" ]; then download_services; fi

echo -e "${BLUE}Skip nginx installation and configuration? ${ORANGE}[yes/NO]:${NC}"
read type
if [ "$type" != "yes" ]; then install_nginx; fi

echo -e "${BLUE}Skip cron job installation and configuration? ${ORANGE}[yes/NO]:${NC}"
read type
if [ "$type" != "yes" ]; then install_cronjob; fi

echo -e "${BLUE}Skip boot scripts installation and configuration? ${ORANGE}[yes/NO]:${NC}"
read type

if [ "$type" != "yes" ]; then
    make_initd hub
    echo
    make_initd youtrack
    echo
    make_initd upsource

    echo -e "${NC}${DIM}Stopping services...${NC}"
    service upsource stop
    service youtrack stop
    service hub stop

    echo -e "${BLUE}Skip services initialization and configuration? ${ORANGE}[yes/NO]:${NC}"
    read type
    if [ "$type" != "yes" ]; then config_services "initd_created"; fi

    echo
    echo -e "${BLUE}Skip configuration of swapfile? ${ORANGE}[yes/NO]:${NC}"
    read type
    if [ "$type" != "yes" ]; then config_swapfile ; fi

    echo -e "${BLUE}Skip system reboot? ${ORANGE}[yes/NO]:${NC}"
        read type
    if [ "$type" != "yes" ]; then reboot; fi
    exit 0
fi

echo -e "${BLUE}Skip services initialization and configuration? ${ORANGE}[yes/NO]:${NC}"
read type
if [ "$type" != "yes" ]; then config_services ; fi

echo -e "${BLUE}Skip configuration of swapfile? ${ORANGE}[yes/NO]:${NC}"
read type
if [ "$type" != "yes" ]; then config_swapfile ; fi

echo -e "${BLUE}Skip system reboot? ${ORANGE}[yes/NO]:${NC}"
read type
if [ "$type" != "yes" ]; then reboot; fi