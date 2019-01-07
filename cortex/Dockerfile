FROM debian:buster

RUN apt-get -y update

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

RUN apt-get -y install gnupg2 apt-transport-https ca-certificates git ruby-hocon
RUN echo 'deb https://dl.bintray.com/thehive-project/debian-stable any main' |  tee -a /etc/apt/sources.list.d/thehive-project.list
RUN apt-key adv --keyserver hkp://pgp.circl.lu --recv-key 562CBC1C
RUN apt-get -y update
RUN apt-get -y install cortex
RUN apt-get -y install python-pip python3-pip python3-dev python3 ssdeep libfuzzy-dev libfuzzy2 libimage-exiftool-perl libmagic1 build-essential libssl-dev
WORKDIR /opt
RUN git clone https://github.com/CERT-BDF/Cortex-Analyzers

RUN for requirement in $(ls -1 /opt/Cortex-Analyzers/analyzers/*/requirements.txt); do pip2 install -r ${requirement}; done
RUN for requirement in $(ls -1 /opt/Cortex-Analyzers/analyzers/*/requirements.txt); do pip3 install -r ${requirement}; done

RUN pip3 install cortexutils requests



WORKDIR /opt/cortex

# Copy entrypoint
COPY ./entrypoint.sh /sbin/entrypoint.sh
RUN chmod 0700 /sbin/entrypoint.sh


RUN mv /etc/cortex/application.conf /tmp/application.conf.default
RUN mv /etc/cortex/logback.xml /tmp/logback.xml.default

EXPOSE 9001

ENTRYPOINT ["/sbin/entrypoint.sh"]
