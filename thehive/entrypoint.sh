#!/bin/bash

ES_HOSTNAME=elasticsearch
CONFIG_SECRET=1
CONFIG_ES=1
CONFIG_CORTEX=1
CORTEX_HOSTNAME=cortex
CORTEX_PROTO=http
CORTEX_PORT=9001
CORTEX_URLS=()
CONFIG=1
CONFIG_FILE=/etc/thehive/application.conf

function usage {
	cat <<- _EOF_
		Available options:
		--no-config		| do not try to configure TheHive (add secret and elasticsearch)
		--no-config-secret	| do not add random secret to configuration
		--no-config-es		| do not add elasticsearch hosts to configuration
		--es-hosts <esconfig>	| use this string to configure elasticsearch hosts (format: ["host1:9300","host2:9300"])
		--es-hostname <host>	| resolve this hostname to find elasticseach instances
		--secret <secret>	| secret to secure sessions
		--cortex-proto <proto>	| define protocol to connect to Cortex (default: http)
		--cortex-port <port>	| define port to connect to Cortex (default: 9000)
		--cortex-url <url>	| add Cortex connection
		--cortex-hostname <host>| resolve this hostname to find Cortex instances
	_EOF_
	exit 1
}

if [ ! -f $CONFIG_FILE ]; then
	hocon -i /tmp/application.conf.default set search.host [\"elasticsearch\:9300\"] | \
		hocon set cortex.default-cortex.url \"http\:\/\/cortex\:9001\" | \
		hocon -o /etc/thehive/application.conf  set cortex.default-cortex.key \"my_api_key\"
fi

if [ ! -f /etc/thehive/logback.xml ]; then
    cp /tmp/logback.xml.default /etc/thehive/logback.xml 
fi

STOP=0
while test $# -gt 0 -o $STOP = 1
do
	case "$1" in
		"--no-config")		CONFIG=0;;
		"--no-config-secret")	CONFIG_SECRET=0;;
		"--secret")		shift; SECRET=$1;;
		"--no-config-es")	CONFIG_ES=0;;
		"--es-hosts")		shift; ES_HOSTS=$1;;
		"--es-hostname")	shift; ES_HOSTNAME=$1;;
		"--no-config-cortex")	CONFIG_CORTEX=0;;
		"--cortex-proto")	shift; CORTEX_PROTO=$1;;
		"--cortex-port")	shift; CORTEX_PORT=$1;;
		"--cortex-url")		shift; CORTEX_URLS+=($1);;
		"--cortex-hostname")	shift; CORTEX_HOSTNAME=$1;;
		"--")			STOP=1;;
		*)			usage
	esac
	shift
done

if test $CONFIG = 1
then
	CONFIG_FILE=$(mktemp).conf
	if test $CONFIG_SECRET = 1
	then
		if test -z "$SECRET"
		then
			SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
		fi
		echo Using secret: $SECRET
		echo play.http.secret.key=\"$SECRET\" >> $CONFIG_FILE
	fi

	if test $CONFIG_ES = 1
	then
		if test -z "$ES_HOSTS"
		then
			function join_es_hosts {
				echo -n "[\"$1"
				shift
				printf "%s:9300\"]" "${@/#/:9300\",\"}"
			}

			ES=$(getent ahostsv4 $ES_HOSTNAME | awk '{ print $1 }' | sort -u)
			if test -z "$ES"
			then
				echo "Warning automatic elasticsearch host config fails"
			else
				ES_HOSTS=$(join_es_hosts $ES)
			fi
		fi
		if test -n "$ES_HOSTS"
		then
			echo Using elasticsearch host: $ES_HOSTS
			echo search.host=$ES_HOSTS >> $CONFIG_FILE
		else
			echo elasticsearch host not configured
		fi
	fi

	if test $CONFIG_CORTEX = 1
	then
		if test -n "$CORTEX_HOSTNAME"
		then
			CORTEX_URLS+=($(getent ahostsv4 $CORTEX_HOSTNAME | awk "{ print \"$CORTEX_PROTO://\"\$1\":$CORTEX_PORT\" }" | sort -u))
		fi

		if test ${#CORTEX_URLS[@]} -gt 0
		then
			echo "play.modules.enabled += connectors.cortex.CortexConnector" >> $CONFIG_FILE
		fi
		I=1
		for C in ${CORTEX_URLS[@]}
		do
			echo Add Cortex cortex$I: $C
			echo cortex.cortex$I.url=\"$C\" >> $CONFIG_FILE
			I=$(($I+1))
		done
	fi

	echo 'include file("/etc/thehive/application.conf")' >> $CONFIG_FILE
fi

exec /opt/thehive/bin/thehive \
	-Dconfig.file=$CONFIG_FILE \
	-Dlogger.file=/etc/thehive/logback.xml \
	-Dpidfile.path=/dev/null \
	-Djavax.net.ssl.trustStore=/etc/thehive/truststore.jks \
	$@