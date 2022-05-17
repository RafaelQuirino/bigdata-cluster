from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from datetime import datetime


dag = DAG('test_dag', 
    description='Test DAG',
    schedule_interval=None,
    start_date=datetime(2022, 5, 17), 
    catchup=False
)

hdfs_operator = BashOperator(
    task_id='hdfs_task', 
    bash_command=f'sh /workspace/hdfs-commands.sh ', 
    dag=dag
)

hive_operator = BashOperator(
    task_id='hive_task', 
    bash_command=f'hive -f /workspace/hive-commands.hql ', 
    dag=dag
)

spark_operator = BashOperator(
    task_id='spark_task', 
    bash_command=f'spark-submit /workspace/pyspark_job.py ', 
    dag=dag
)

hdfs_operator \
    >> hive_operator \
        >> spark_operator