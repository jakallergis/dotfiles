#!/bin/bash
apt-get -qq update
apt-get -qq install mc htop git unzip wget curl -y

C_BLUE="\e[34m"
NO_COLOR="\e[0m"

echo
echo "====================================================="
echo "                     WELCOME"
echo "====================================================="
echo
echo "Hub"
echo "download https://www.jetbrains.com/hub/download/"
echo "read instruction https://www.jetbrains.com/hub/help/1.0/Installing-Hub-with-Zip-Distribution.html"
echo "install into /usr/jetbrains/youtrack/"
echo "====================================="
echo
echo "YouTrack"
echo "download https://www.jetbrains.com/youtrack/download/get_youtrack.html"
echo "read instruction https://confluence.jetbrains.com/display/YTD65/Installing+YouTrack+with+ZIP+Distribution#InstallingYouTrackwithZIPDistribution-InstallingNewYouTrackServer"
echo "install into /usr/jetbrains/youtrack/"
echo "====================================="
echo
echo "Upsource"
echo "download https://www.jetbrains.com/upsource/download/"
echo "read the first https://www.jetbrains.com/upsource/help/2.0/prerequisites.html"
echo "install into /usr/jetbrains/upsource/"
echo "====================================="
echo

echo "==================================="
echo "In order to continue installing we need to set a few properties for nginx."

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
echo "Debian codename: ${code}"
echo

mkdir -p /var/tmp
pushd /var/tmp

ask_param () {
    if [ "$1" == "base_domain" ]; then
        echo -n "Base domain url (Default: http://localhost): "
        read base_domain
    fi

    if [ "$1" == "hub_domain" ]; then
        echo -n "Hub domain url: (Default: http://localhost): "
        read hub_domain
    fi

    if [ "$1" == "hub_port" ]; then
        echo -n "hub port: (Default: 8080): "
        read hub_port
    fi

    if [ "$1" == "yt_domain" ]; then
        echo -n "Youtrack domain url: (Default: http://localhost): "
        read yt_domain
    fi

    if [ "$1" == "yt_port" ]; then
        echo -n "Youtrack port: (Default: 8081): "
        read yt_port
    fi

    if [ "$1" == "us_domain" ]; then
        echo -n "Upsource domain url: (Default: http://localhost): "
        read us_domain
    fi

    if [ "$1" == "us_port" ]; then
        echo -n "Upsource port: (Default: 8082): "
        read us_port
    fi

    if [ "$1" == "cron_email" ]; then
        echo -n "Cron email: "
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
	echo "================="
	echo
	echo "Base domain url: ${C_BLUE}${base_domain}${NO_COLOR}"
	echo "Hub domain url: ${C_BLUE}${hub_domain}${NO_COLOR}"
	echo "hub port: ${C_BLUE}${hub_port}${NO_COLOR}"
	echo "Youtrack domain url: ${C_BLUE}${yt_domain}${NO_COLOR}"
	echo "Youtrack port: ${C_BLUE}${yt_port}${NO_COLOR}"
	echo "Upsource domain url: ${C_BLUE}${us_domain}${NO_COLOR}"
	echo "Upsource port: ${C_BLUE}${us_port}${NO_COLOR}"
	echo "Cron email: ${C_BLUE}${cron_email}${NO_COLOR}"
	echo
	echo "================="
}

install_java() {
    version_to_install=7
    if [ "$1" == 8 ]; then
        version_to_install=8
    fi

    echo
    echo "Installing Java JDK 1.8"
    echo

    add-apt-repository ppa:openjdk-r/ppa -y
    echo "Updating Packages..."
    apt-get -qq update
    echo "Installing..."
    apt-get install openjdk-${version_to_install}-jre -y

    echo
    echo "Java was successfully Installed"
    echo
}

download_services() {
    mkdir -p /usr/jetbrains/youtrack /usr/jetbrains/hub /usr/jetbrains/upsource

    echo "Downloading Hub..."
    wget -qq https://download.jetbrains.com/hub/2017.2/hub-ring-bundle-2017.2.6307.zip -O /usr/jetbrains/hub/arch.zip
    echo "Downloading Youtrack..."
    wget -qq https://download.jetbrains.com/charisma/youtrack-2017.2.34480.zip -O /usr/jetbrains/youtrack/arch.zip
    echo "Downloading Upsource..."
    wget -qq https://download.jetbrains.com/upsource/upsource-2017.2.2057.zip -O /usr/jetbrains/upsource/arch.zip

    pushd /usr/jetbrains/hub
    echo "Exctracting Hub..."
    unzip -qq arch.zip
    mv hub-ring-bundle-2017.2.6307/* .
    rm -rf hub-ring-bundle-2017.2.6307
    chmod +x -R ../hub/
    popd

    pushd /usr/jetbrains/youtrack
    echo "Exctracting Youtrack..."
    unzip -qq arch.zip
    mv youtrack-2017.2.34480/* .
    rm -rf youtrack-2017.2.34480
    chmod +x -R ../youtrack/
    popd

    pushd /usr/jetbrains/upsource
    echo "Exctracting Upsource..."
    unzip -qq arch.zip
    mv upsource-2017.2.2057/* .
    rm -rf upsource-2017.2.2057
    chmod +x -R ../upsource/
    popd
    popd
}

make_initd() {

  echo "making init.d for $1"

  rq="hub "
  if [ "$1" == "hub" ]; then
    rq=""
  fi

  cat >/etc/init.d/$1 <<EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:          $1
# Required-Start:    ${rq}\$local_fs \$remote_fs \$network \$syslog \$named
# Required-Stop:     ${rq}\$local_fs \$remote_fs \$network \$syslog \$named
# Default-Start:     2 3 4 5
# Default-Stop:      S 0 1 6
# Short-Description: initscript for $1
# Description:       initscript for $1
### END INIT INFO
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=$1
SCRIPT=/usr/jetbrains/\$NAME/bin/\$NAME.sh
do_start() {
  \$SCRIPT start soft
}
case "\$1" in
  start)
    do_start
    ;;
  stop|restart|status|run|rerun|help)
    \$SCRIPT \$1 \$2
    ;;
  *)
    echo "Usage: sudo /etc/init.d/$1 {start|stop|restart|status|run|rerun}" >&2
    exit 1
    ;;
esac
exit 0
EOF

  chmod +x /etc/init.d/$1

  update-rc.d $1 defaults
  if [ "$1" != "hub" ]; then
    update-rc.d $1 disable
  fi
}

install_nginx() {
    echo
    echo "configure nginx"
    apt-get install -t ${code}-backports nginx -y

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
    service upsource stop
    service youtrack stop
    service hub stop

    /usr/jetbrains/hub/bin/hub.sh configure --listen-port ${hub_port} --base-url http://${hub_domain}
    /usr/jetbrains/youtrack/bin/youtrack.sh configure --listen-port ${yt_port} --base-url http://${yt_domain}
    /usr/jetbrains/upsource/bin/upsource.sh configure --listen-port ${us_port} --base-url http://${us_domain}

    service hub start
    service youtrack start
    service upsource start

    echo "goto setup"
    echo $hub_domain
    echo $yt_domain
    echo $us_domain
}

type="no"
echo -n "Skip urls and ports input? [yes/NO]:"
read type

if [ "$type" == "no" ]; then
  ask_param base_domain
  check_param base_domain ${base_domain}
  echo "${C_BLUE}${base_domain}${NO_COLOR}"
  ask_param hub_domain
  check_param hub_domain ${hub_domain}
  echo "${C_BLUE}${hub_domain}${NO_COLOR}"
  ask_param hub_port
  check_param hub_port ${hub_port}
  echo "${C_BLUE}${hub_port}${NO_COLOR}"
  ask_param yt_domain
  check_param yt_domain ${yt_domain}
  echo "${C_BLUE}${yt_domain}${NO_COLOR}"
  ask_param yt_port
  check_param yt_port ${yt_port}
  echo "${C_BLUE}${yt_port}${NO_COLOR}"
  ask_param us_domain
  check_param us_domain ${us_domain}
  echo "${C_BLUE}${us_domain}${NO_COLOR}"
  ask_param us_port
  check_param us_port ${us_port}
  echo "${C_BLUE}${us_port}${NO_COLOR}"
  ask_param cron_email
  if [ "${cron_email}" != "" ]; then echo "${C_BLUE}${us_port}${NO_COLOR}"; fi
fi

print_params

type="no"
echo -n "Skip installation of OpenJDK? [yes|no]"
read type

if [ "$type" == "no" ]; then
  install_java
fi

type="no"
echo -n "Skip Download of Services? [yes|no]"
read type

if [ "$type" == "no" ]; then
  download_services
fi

type="no"
echo -n "Skip boot scripts installation and configuration? [yes/no]:"
read type

if [ "$type" == "no" ]; then
    echo
    make_initd youtrack
    echo
    make_initd hub
    echo
    make_initd upsource
fi

type="no"
echo -n "Skip nginx installation and configuration? [yes/no]:"
read type

if [ "$type" == "no" ]; then
  install_nginx
fi

type="no"
echo -n "Skip cron job installation and configuration? [yes/no]:"
read type

if [ "$type" == "no" ]; then
  install_cronjob
fi

type="no"
echo -n "Skip services initialization and configuration? [yes/no]:"
read type

if [ "$type" == "no" ]; then
  install_cronjob
fi