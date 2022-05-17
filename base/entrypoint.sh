#!/bin/bash


if [ -n "${HADOOP_DATANODE_UI_PORT}" ]; then
  echo "Replacing default datanode UI port 9864 with ${HADOOP_DATANODE_UI_PORT}"
  sed -i "$ i\<property><name>dfs.datanode.http.address</name><value>0.0.0.0:${HADOOP_DATANODE_UI_PORT}</value></property>" ${HADOOP_CONF_DIR}/hdfs-site.xml
fi


if [ "${HADOOP_NODE}" == "namenode" ]; then
  echo "Starting Hadoop name node..."
  if [ ! -f ${FLAGS_HOME}/HDFS_FORMATTED ]; then
    touch ${FLAGS_HOME}/HDFS_FORMATTED
    yes | hdfs namenode -format
  fi
  hdfs --daemon start namenode
  hdfs --daemon start secondarynamenode
  yarn --daemon start resourcemanager
  mapred --daemon start historyserver

  # Jupyter lab
  screen -S jupyterlab -d -m jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=

  # Airflow
  screen -S airflow -d -m airflow standalone
fi


if [ "${HADOOP_NODE}" == "datanode" ]; then
  echo "Starting Hadoop data node..."
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi


if [ -n "${HIVE_CONFIGURE}" ]; then
  echo "Configuring Hive..."
  schematool -dbType postgres -initSchema
  screen -S hivemetastore -d -m hive --service metastore
  # JDBC Server.
  screen -S hiveserver2 -d -m hiveserver2
  # For HUE (for some reason...)
  screen -S hive -d -m hive
fi


if [ -z "${SPARK_MASTER_ADDRESS}" ]; then
  echo "Starting Spark master node..."

  # Create directory for Spark logs
  SPARK_LOGS_HDFS_PATH=/log/spark
  if ! hadoop fs -test -d "${SPARK_LOGS_HDFS_PATH}"
  then
    hadoop fs -mkdir -p  ${SPARK_LOGS_HDFS_PATH}
    hadoop fs -chmod -R 755 ${SPARK_LOGS_HDFS_PATH}/*
  fi

  # Spark on YARN
  SPARK_JARS_HDFS_PATH=/spark-jars
  if ! hadoop fs -test -d "${SPARK_JARS_HDFS_PATH}"
  then
    hadoop dfs -copyFromLocal "${SPARK_HOME}/jars" "${SPARK_JARS_HDFS_PATH}"
  fi

  "${SPARK_HOME}/sbin/start-master.sh" -h master &
  "${SPARK_HOME}/sbin/start-history-server.sh" &
else
  echo "Starting Spark worker node..."
  "${SPARK_HOME}/sbin/start-slave.sh" "${SPARK_MASTER_ADDRESS}" &
fi


echo "All initializations finished!"


# Blocking call to view all logs. This is what won't let container exit right away.
/scripts/parallel_commands.sh "scripts/watchdir ${HADOOP_LOG_DIR}" "scripts/watchdir ${SPARK_LOG_DIR}"


# Stop all
if [ "${HADOOP_NODE}" == "namenode" ]; then
  hdfs --daemon stop namenode
  hdfs --daemon stop secondarynamenode
  yarn --daemon stop resourcemanager
  mapred --daemon stop historyserver
  screen -X -S jupyterlab quit
  screen -X -S airflow quit
fi
if [ -n "${HIVE_CONFIGURE}" ]; then
  screen -X -S hivemetastore quit
  screen -X -S hiveserver2 quit
  screen -X -S hive quit
fi
if [ "${HADOOP_NODE}" == "datanode" ]; then
  hdfs --daemon stop datanode
  yarn --daemon stop nodemanager
fi