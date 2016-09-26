FROM java:8
WORKDIR ~/
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y ant
RUN apt-get install -y git
RUN echo mysql-server mysql-server/root_password select l3tm31n | debconf-set-selections
RUN echo mysql-server mysql-server/root_password_again select l3tm31n | debconf-set-selections
RUN apt-get -y install mysql-server libmysql-java
RUN service mysql start && mysql --user=root --password=l3tm31n -e "CREATE DATABASE konakart; CREATE USER 'konakart'@'127.0.0.1' IDENTIFIED BY 'k0n4k4rt'; GRANT ALL ON konakart.* TO 'konakart'@'127.0.0.1'; CREATE USER 'konakart'@'localhost' IDENTIFIED BY 'k0n4k4rt'; GRANT ALL ON konakart.* TO 'konakart'@'localhost'; CREATE USER 'monitor'@'localhost' IDENTIFIED BY 'appd123'; GRANT ALL PRIVILEGES ON *.* TO 'monitor'@'localhost' WITH GRANT OPTION; CREATE USER 'monitor'@'%' IDENTIFIED BY 'appd123'; GRANT ALL PRIVILEGES ON *.* TO 'monitor'@'%' WITH GRANT OPTION;"
RUN wget https://github.com/sandbreak80/docker_konakart/releases/download/8.1/KonaKart-8.1.0.0-Linux-Install-64 -O KonaKart-8.1.0.0-Linux-Install-64
RUN chmod +x KonaKart-8.1.0.0-Linux-Install-64
RUN ./KonaKart-8.1.0.0-Linux-Install-64 -S -DDatabaseType mysql -DDatabaseUrl jdbc:mysql://localhost:3306/konakart -DDatabaseUsername konakart -DDatabasePassword k0n4k4rt -DJavaJRE /usr/lib/jvm/java-8-openjdk-amd64/jre
RUN service mysql start && mysql -p konakart --user=konakart --password=k0n4k4rt < /usr/local/konakart/database/MySQL/konakart_demo.sql
RUN wget https://github.com/sandbreak80/docker_konakart/releases/download/8.1/konakart.sql -O /usr/local/konakart/database/MySQL/konakart.sql
RUN service mysql start && mysql -p konakart --user=konakart --password=k0n4k4rt < /usr/local/konakart/database/MySQL/konakart.sql
CMD service mysql start && /usr/local/konakart/bin/startkonakart.sh
RUN sleep 300s
RUN cd /usr/local/konakart/java_soap_examples/ && ant -p && ant
RUN cd /usr/local/konakart/java_api_examples/ && ant -p && ant
RUN sleep 120s
RUN cd /usr/local/konakart/custom/ && ./bin/ant enableWebServices
RUN sleep 60s
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
RUN cd /home && mkdir /home/appdynamics && mkdir /home/appdynamics/java_agent
RUN wget http://www.sandbreak.com/AppServerAgent.zip -O /home/appdynamics/AppServerAgent.zip
RUN unzip /home/appdynamics/AppServerAgent.zip -d /home/appdynamics/java_agent/
RUN cd /usr/local/konakart/bin && touch /usr/local/konakart/bin/setenv.sh
RUN echo 'export CATALINA_OPTS="$CATALINA_OPTS -javaagent:/home/appdynamics/java_agent/javaagent.jar -Dappdynamics.controller.hostName=devopslabappsphere -Dappdynamics.controller.port=8090 -Dappdynamics.agent.applicationName=KonaKart -Dappdynamics.agent.tierName=Kona_Server -Dappdynamics.agent.nodeName=Node1"' >> /usr/local/konakart/bin/setenv.sh
CMD service mysql start && /usr/local/konakart/bin/startkonakart.sh && tail -F /usr/local/konakart/logs/catalina.out
EXPOSE 8780
EXPOSE 3306
