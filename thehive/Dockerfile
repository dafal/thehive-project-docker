FROM debian:buster

# Install TheHive repository
RUN apt-get -y update
RUN apt-get -y install gnupg2 apt-transport-https ca-certificates ruby-hocon
RUN echo 'deb https://dl.bintray.com/thehive-project/debian-stable any main' |  tee -a /etc/apt/sources.list.d/thehive-project.list
RUN apt-key adv --keyserver hkp://pgp.circl.lu --recv-key 562CBC1C
RUN apt-get -y update
RUN apt-get -y install thehive

# Copy entrypoint
COPY ./entrypoint.sh /sbin/entrypoint.sh
RUN chmod 0700 /sbin/entrypoint.sh

# Create copies of the default configuration files
RUN mv /etc/thehive/application.conf /tmp/application.conf.default
RUN mv /etc/thehive/logback.xml /tmp/logback.xml.default

EXPOSE 9000

ENTRYPOINT ["/sbin/entrypoint.sh"]
