FROM oraclelinux:8.8

USER root

RUN dnf -y install wget && \
    dnf -y install unzip && \
    cd /tmp && \
    wget https://oca.opensource.oracle.com/gds/GRAALVM_EE_JAVA17_22_3_2/graalvm-ee-java17-linux-amd64-22.3.2.tar.gz && \
    tar -xzf graalvm-ee-java17-linux-amd64-22.3.2.tar.gz && \
    mv graalvm-ee-java17-22.3.2/ /opt/graalvm-java17/

ENV JAVA_HOME=/opt/graalvm-java17
ENV PATH="${PATH}:${JAVA_HOME}/bin"

RUN dnf -y install oracle-instantclient-release-el8 && \
    dnf -y install oracle-instantclient-basic && \
    dnf -y install oracle-instantclient-sqlplus

RUN mkdir -p /tmp/ords && \
    cd /tmp/ords && \
    wget https://download.oracle.com/otn_software/java/ords/ords-23.1.3.137.1032.zip && \
    unzip ords-23.1.3.137.1032.zip && \
    rm -rf ords-23.1.3.137.1032.zip && \
    cd .. && \
    mv ords/ /opt/ords/

ENV PATH="${PATH}:/opt/ords/bin"

WORKDIR /etc/ords/config
ENV RUN_FILE="runOrds.sh"
COPY $RUN_FILE /opt/ords/

RUN adduser oracle && usermod -a -G oracle oracle

RUN chmod ug+x /opt/ords/*.sh && chown oracle:oracle /opt/ords/*.sh && chown oracle:oracle /etc/ords/config

USER oracle:oracle

EXPOSE 27017

CMD /opt/ords/$RUN_FILE
