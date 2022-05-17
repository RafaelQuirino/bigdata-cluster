FROM ubuntu:20.04


ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y apt-utils
RUN apt-get install -y \
    wget \
    curl \
    unzip \
    findutils \
    gcc g++-8 libc6 \
    libncurses5-dev libncursesw5-dev \
    && ln -s /lib64/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2


# Install Java 8
RUN apt-get -y install openjdk-8-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64


# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]


# Hadoop
ENV HADOOP_VERSION=3.0.0
ENV HADOOP_HOME /usr/hadoop
###############################################################################
RUN curl --progress-bar -L --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && mv "/usr/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}" \
 && rm -rf "${HADOOP_HOME}/share/doc" \
 && chown -R root:root "${HADOOP_HOME}"
###############################################################################
# COPY "systems/hadoop-${HADOOP_VERSION}" "/usr/hadoop-${HADOOP_VERSION}"
# RUN mv "/usr/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}" \
#     && rm -rf "${HADOOP_HOME}/share/doc" \
#     && chown -R root:root "${HADOOP_HOME}"
###############################################################################


# Hive
ENV HIVE_VERSION=2.3.2
ENV HIVE_HOME=/usr/hive
ENV HIVE_CONF_DIR="${HIVE_HOME}/conf"
ENV PATH "${PATH}:${HIVE_HOME}/bin"
###############################################################################
RUN curl --progress-bar -L \
  "https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz" \
    | gunzip \
    | tar -x -C /usr/ \
  && mv "/usr/apache-hive-${HIVE_VERSION}-bin" "${HIVE_HOME}" \
  && chown -R root:root "${HIVE_HOME}" \
  && mkdir -p "${HIVE_HOME}/hcatalog/var/log" \
  && mkdir -p "${HIVE_HOME}/var/log" \
  && mkdir -p "${HIVE_CONF_DIR}" \
  && chmod 777 "${HIVE_HOME}/hcatalog/var/log" \
  && chmod 777 "${HIVE_HOME}/var/log"
###############################################################################
# COPY "systems/apache-hive-${HIVE_VERSION}-bin" "/usr/apache-hive-${HIVE_VERSION}-bin"
# RUN mv "/usr/apache-hive-${HIVE_VERSION}-bin" "${HIVE_HOME}" \
#   && chown -R root:root "${HIVE_HOME}" \
#   && mkdir -p "${HIVE_HOME}/hcatalog/var/log" \
#   && mkdir -p "${HIVE_HOME}/var/log" \
#   && mkdir -p "${HIVE_CONF_DIR}" \
#   && chmod 777 "${HIVE_HOME}/hcatalog/var/log" \
#   && chmod 777 "${HIVE_HOME}/var/log"
###############################################################################
# Creating directory for Hive external jars e download parquet support
RUN wget https://repo1.maven.org/maven2/com/twitter/parquet-avro/1.2.5/parquet-avro-1.2.5.jar -P /usr/hive/aux_jars/
###############################################################################

# Making Hive work with Hadoop (guava version mismatch)
RUN rm "${HIVE_HOME}/lib/guava-14.0.1.jar" \
 && cp "${HADOOP_HOME}/share/hadoop/hdfs/lib/guava-11.0.2.jar" "${HIVE_HOME}/lib/"


# Spark
ENV SPARK_VERSION=3.0.0
ENV SPARK_PACKAGE "spark-${SPARK_VERSION}-bin-without-hadoop"
ENV SPARK_HOME /usr/spark
###############################################################################
RUN curl --progress-bar -L --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv "/usr/${SPARK_PACKAGE}" "${SPARK_HOME}" \
 && chown -R root:root "${SPARK_HOME}"
###############################################################################
# COPY "./systems/spark-${SPARK_VERSION}-bin-without-hadoop" "/usr/spark-${SPARK_VERSION}-bin-without-hadoop"
# RUN mv "/usr/${SPARK_PACKAGE}" "${SPARK_HOME}" \
#   && chown -R root:root "${SPARK_HOME}"
###############################################################################
# For inscrutable reasons, Spark distribution doesn't include spark-hive.jar
# Livy attempts to load it though, and will throw
# java.lang.ClassNotFoundException: org.apache.spark.sql.hive.HiveContext
ARG SCALA_VERSION=2.12
RUN curl --progress-bar -L \
    "https://repo1.maven.org/maven2/org/apache/spark/spark-hive_${SCALA_VERSION}/${SPARK_VERSION}/spark-hive_${SCALA_VERSION}-${SPARK_VERSION}.jar" \
    --output "${SPARK_HOME}/jars/spark-hive_${SCALA_VERSION}-${SPARK_VERSION}.jar"


# PySpark - comment out if you don't want it in order to save image space
RUN apt-get install -y \
    python3 \
    python3-dev \
    python3-pip
RUN ln -s /usr/bin/python3 /usr/bin/python


# findspark
RUN pip3 install findspark


# Jupyterlab
RUN pip3 install jupyterlab


# Airflow
RUN pip install WTForms==2.3.3 \
    && pip3 install apache-airflow \
    && airflow db init \
    && airflow users  create --role Admin --username admin --email admin --firstname admin --lastname admin --password admin
    # && airflow users create -e "admin@example.com" -f "Admin" -l "User" -p "admin" -u "admin" -r Admin
    # It seems like this last command is not working.
    # Instead, look at ./airflow/standalone_admin_password.txt for the first
    # default password create for user "admin".


# Other tools
RUN apt-get install -y \
    screen \
    nano 


# Common settings
ENV PATH="${PATH}:${JAVA_HOME}/bin"
# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1


# Hadoop setup
ENV PATH="${PATH}:${HADOOP_HOME}/bin"
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"
ENV LD_LIBRARY_PATH="${HADOOP_HOME}/lib/native:${LD_LIBRARY_PATH}"
ENV HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
ENV HADOOP_LOG_DIR="${HADOOP_HOME}/logs"
COPY ./conf/hadoop/core-site.xml "${HADOOP_CONF_DIR}"
COPY ./conf/hadoop/hadoop-env.sh "${HADOOP_CONF_DIR}"
COPY ./conf/hadoop/hdfs-site.xml "${HADOOP_CONF_DIR}"
COPY ./conf/hadoop/mapred-site.xml "${HADOOP_CONF_DIR}"
COPY ./conf/hadoop/workers "${HADOOP_CONF_DIR}"
COPY ./conf/hadoop/yarn-site.xml "${HADOOP_CONF_DIR}"


# For S3 to work. Without this line you'll get "Class org.apache.hadoop.fs.s3a.S3AFileSystem not found" exception when accessing S3 from Hadoop
ENV HADOOP_CLASSPATH="${HADOOP_HOME}/share/hadoop/tools/lib/*"


# Hive setup
ENV PATH="${PATH}:${HIVE_HOME}/bin"
ENV HADOOP_CLASSPATH="${HADOOP_CLASSPATH}:${HIVE_HOME}/lib/*"
COPY conf/hive/hive-site.xml "${HIVE_CONF_DIR}/"
COPY conf/hive/hive-env.sh "${HIVE_CONF_DIR}/"


# Spark setup
ENV PATH="${PATH}:${SPARK_HOME}/bin"
ENV SPARK_CONF_DIR="${SPARK_HOME}/conf"
ENV SPARK_LOG_DIR="${SPARK_HOME}/logs"
ENV SPARK_DIST_CLASSPATH="${HADOOP_CONF_DIR}:${HADOOP_HOME}/share/hadoop/tools/lib/*:${HADOOP_HOME}/share/hadoop/common/lib/*:${HADOOP_HOME}/share/hadoop/common/*:${HADOOP_HOME}/share/hadoop/hdfs:${HADOOP_HOME}/share/hadoop/hdfs/lib/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/mapreduce/lib/*:${HADOOP_HOME}/share/hadoop/mapreduce/*:${HADOOP_HOME}/share/hadoop/yarn:${HADOOP_HOME}/share/hadoop/yarn/lib/*:${HADOOP_HOME}/share/hadoop/yarn/*"
COPY conf/hadoop/core-site.xml "${SPARK_CONF_DIR}"/
COPY conf/hadoop/hdfs-site.xml "${SPARK_CONF_DIR}"/
COPY conf/spark/spark-defaults.conf "${SPARK_CONF_DIR}"/
# Spark with Hive
ENV SPARK_DIST_CLASSPATH=$SPARK_DIST_CLASSPATH:$HIVE_HOME/lib/*
COPY ./conf/hive/hive-site.xml $SPARK_CONF_DIR/
RUN ln -s $SPARK_HOME/jars/scala-library-*.jar $HIVE_HOME/lib \
   && ln -s $SPARK_HOME/jars/spark-core_*.jar $HIVE_HOME/lib \
   && ln -s $SPARK_HOME/jars/spark-network-common_*.jar $HIVE_HOME/lib


# Clean up
RUN rm -rf "${HIVE_HOME}/examples" \
    && rm -rf "${SPARK_HOME}/examples/src"


# If both YARN Web UI and Spark UI is up, then returns 0, 1 otherwise.
HEALTHCHECK CMD curl -f http://host.docker.internal:8080/ \
    && curl -f http://host.docker.internal:8088/ || exit 1


# Multitail for logging
COPY ./scripts/ /scripts
RUN apt-get install -y linux-headers-$(uname -r) \
    && gcc /scripts/watchdir.c -o /scripts/watchdir \
    && chmod +x /scripts/parallel_commands.sh


# Entry point: start all services and applications.
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
