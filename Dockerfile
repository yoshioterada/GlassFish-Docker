
# Glassfish4 + Oracle JDK 1.8.0
#
# VERSION     0.5
# BUILD       20150828

FROM       ubuntu:latest
MAINTAINER "Yoshio Terada" "Yoshio.Terada@microsoft.com"

# タイムゾーン
RUN echo "Asia/Tokyo" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

# ロケールの設定
RUN locale-gen en_US.UTF-8
RUN locale-gen ja_JP.UTF-8
RUN update-locale LANG=ja_JP.UTF-8 

# Install required Linux packages
RUN apt-get update
RUN apt-get -y install wget
RUN apt-get -y install unzip

#Install Java 1.8
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \ 
  apt-get update && \
  apt-get install software-properties-common -y && \ 
  add-apt-repository -y ppa:webupd8team/java -y && \
  apt-get update && \
  apt-get install oracle-java8-installer -y && \
  apt-get install oracle-java8-set-default && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Install GlassFish 4
RUN wget -q --no-cookies --no-check-certificate "http://download.oracle.com/glassfish/4.1/release/glassfish-4.1.zip"
RUN mv /glassfish-4.1.zip /usr/local; cd /usr/local; unzip glassfish-4.1.zip ; rm -f glassfish-4.1.zip ; cd /

# Setup environment variables
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV GF_HOME /usr/local/glassfish4
ENV PATH $PATH:$JAVA_HOME/bin:$GF_HOME/bin

# Allow Derby to start as daemon (used by some Java EE app, such as Pet Store)
RUN echo "grant { permission java.net.SocketPermission \"localhost:1527\", \"listen\"; };" >> $JAVA_HOME/jre/lib/security/java.policy

# Secure GF installation with a password and authorize network access
ADD password_1.txt /tmp/password_1.txt
ADD password_2.txt /tmp/password_2.txt
RUN asadmin --user admin --passwordfile /tmp/password_1.txt change-admin-password --domain_name domain1 ; asadmin start-domain domain1 ; asadmin --user admin --passwordfile /tmp/password_2.txt enable-secure-admin ; asadmin stop-domain domain1
RUN rm /tmp/password_?.txt

# Add our GF startup script
ADD start-gf.sh /usr/local/bin/start-gf.sh
RUN chmod 755 /usr/local/bin/start-gf.sh

# PORT FORWARD THE ADMIN PORT, HTTP LISTENER-1 PORT, HTTPS LISTENER PORT, PURE JMX CLIENTS PORT, MESSAGE QUEUE PORT, IIOP PORT, IIOP/SSL PORT, IIOP/SSL PORT WITH MUTUAL AUTHENTICATION
#EXPOSE 4848 8080 8181 8686 7676 3700 3820 3920
# ElasticBeanstalk only expose first port
EXPOSE 8080 4848

# deploy an application to the container
# example below - it uses the auto-deploy service of Glassfish
ADD https://github.com/yoshioterada/JavaEE7-App-On-Docker/blob/master/JavaEE7-App-On-Docker/target/JavaEE7-App-On-Docker-1.0-SNAPSHOT.war?raw=true /usr/local/glassfish4/glassfish/domains/domain1/autodeploy/JavaEE7-App-On-Docker.war

ENTRYPOINT ["/usr/local/bin/start-gf.sh"]

