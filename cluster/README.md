# Big data cluster with Hadoop, Spark, Hive, Hue, Jupyter Lab and Airflow via Docker-compose.


## Usage

Bring everything up:
```bash
docker-compose up -d
```

The `data/` and `workspace/` directories are mounted into every node,
and can be used to hold test data and scripts/notebooks/whatever, 
or any user specific data and scripts.
In the default case, `data/` holds `grades.csv` for test data, 
and `workspace/` holds some test scripts to process this data.

Specifically:
* `hdfs_commands.sh`
  * Copy test data in `/data/grades.csv`, to HDFS at `/grades.csv`
* `hive_commands.hql`
  * Create a hive table, loading the data from `/grades.csv`
* `Notebook.ipynb`
  * Create a Spark session and shows data from hive table `grades`
* `pyspark_job.py`
  * Simple job to calculate average grade value for each student
* `pyspark_submit.sh` 
  * Submits `pyspark_job.py`

The `dags/` directory is a place for Airflow dags, and holds some test dags 
that can be started from the Airflow Web UI, executing tasks from the scripts 
at `workspace/`.

The `conf/` directory contains init sql scripts and HUE configuration in file 
`/conf/hue/hue-overrides.ini`.

The `volumes/` directory is there just to mark a place for persisting data 
from the cluster operations like metadata from the namenode, blocks from datanodes,
metadata from Hive, Hue and Airflow, etc.

Hive JDBC port is exposed to host:
* URI: `jdbc:hive2://localhost:10000`
* Driver: `org.apache.hive.jdbc.HiveDriver` (org.apache.hive:hive-jdbc:2.3.2)
* User and password: "postgres", "new_password".

To shut the whole thing down, run this from the same folder:
```bash
docker-compose down
```

## Checking if everything plays well together
To get a sense of how it all works under the hood, follow the instructions below:

### Hadoop and YARN:

Check [YARN (Hadoop ResourceManager) Web UI
(localhost:8088)](http://localhost:8088/).
You should see 2 active nodes there.
There's also an
[alternative YARN Web UI 2 (http://localhost:8088/ui2)](http://localhost:8088/ui2).

Then, [Hadoop Name Node UI (localhost:9870)](http://localhost:9870),
Hadoop Data Node UIs at
[http://localhost:9864](http://localhost:9864) and [http://localhost:9865](http://localhost:9865):
all of those URLs should result in a page.

Open up a shell in the master node and run `jps`.
```bash
docker-compose exec master /bin/bash
jps
```
`jps` command outputs a list of running Java processes,
which on Hadoop Namenode/Spark Master node should include those:
<pre>
Jps
ResourceManager
NameNode
SecondaryNameNode
HistoryServer
Master
</pre>

... but not necessarily in this order and those IDs,
also some extras like `RunJar` and `JobHistoryServer` might be there too.

Then let's see if YARN can see all resources we have (2 worker nodes):
```bash
yarn node -list
```
<pre>
current-datetime INFO client.RMProxy: Connecting to ResourceManager at master/172.28.1.1:8032
Total Nodes:2
         Node-Id	     Node-State	Node-Http-Address	Number-of-Running-Containers
   worker1:45019	        RUNNING	     worker1:8042	                           0
   worker2:41001	        RUNNING	     worker2:8042	                           0
</pre>

HDFS (Hadoop distributed file system) condition:
```bash
hdfs dfsadmin -report
```
<pre>
Live datanodes (2):
Name: 172.28.1.2:9866 (worker1)
...
Name: 172.28.1.3:9866 (worker2)
</pre>

Now we'll upload a file into HDFS and see that it's visible from all
nodes:
```bash
hadoop fs -put /data/grades.csv /
hadoop fs -ls /
```
<pre>
Found N items
...
-rw-r--r--   2 root supergroup  ... /grades.csv
...
</pre>

Ctrl+D out of master now. Repeat for remaining nodes
(there's 3 total: master, worker1 and worker2):

```bash
docker-compose exec worker1 bash
hadoop fs -ls /
```
<pre>
Found 1 items
-rw-r--r--   2 root supergroup  ... /grades.csv
</pre>

While we're on nodes other than Hadoop Namenode/Spark Master node,
jps command output should include DataNode and Worker now instead of
NameNode and Master:
```bash
jps
```
<pre>
123 Jps
456 NodeManager
789 DataNode
234 Worker
</pre>

### Hive

Prerequisite: there's a file `grades.csv` stored in HDFS ( `hadoop fs -put /data/grades.csv /` )
```bash
docker-compose exec master bash
hive
```
```sql
CREATE TABLE grades(
    `Last name` STRING,
    `First name` STRING,
    `SSN` STRING,
    `Test1` DOUBLE,
    `Test2` INT,
    `Test3` DOUBLE,
    `Test4` DOUBLE,
    `Final` DOUBLE,
    `Grade` STRING)
COMMENT 'https://people.sc.fsu.edu/~jburkardt/data/csv/csv.html'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
tblproperties("skip.header.line.count"="1");

LOAD DATA INPATH '/grades.csv' INTO TABLE grades;

SELECT * FROM grades;
-- OK
-- Alfalfa	Aloysius	123-45-6789	40.0	90	100.0	83.0	49.0	D-
-- Alfred	University	123-12-1234	41.0	97	96.0	97.0	48.0	D+
-- Gerty	Gramma	567-89-0123	41.0	80	60.0	40.0	44.0	C
-- Android	Electric	087-65-4321	42.0	23	36.0	45.0	47.0	B-
-- Bumpkin	Fred	456-78-9012	43.0	78	88.0	77.0	45.0	A-
-- Rubble	Betty	234-56-7890	44.0	90	80.0	90.0	46.0	C-
-- Noshow	Cecil	345-67-8901	45.0	11	-1.0	4.0	43.0	F
-- Buff	Bif	632-79-9939	46.0	20	30.0	40.0	50.0	B+
-- Airpump	Andrew	223-45-6789	49.0	1	90.0	100.0	83.0	A
-- Backus	Jim	143-12-1234	48.0	1	97.0	96.0	97.0	A+
-- Carnivore	Art	565-89-0123	44.0	1	80.0	60.0	40.0	D+
-- Dandy	Jim	087-75-4321	47.0	1	23.0	36.0	45.0	C+
-- Elephant	Ima	456-71-9012	45.0	1	78.0	88.0	77.0	B-
-- Franklin	Benny	234-56-2890	50.0	1	90.0	80.0	90.0	B-
-- George	Boy	345-67-3901	40.0	1	11.0	-1.0	4.0	B
-- Heffalump	Harvey	632-79-9439	30.0	1	20.0	30.0	40.0	C
-- Time taken: 3.324 seconds, Fetched: 16 row(s)
```

Ctrl+D back to bash. Check if the file's been loaded to Hive warehouse
directory:

```bash
hadoop fs -ls /usr/hive/warehouse/grades
```
<pre>
Found 1 items
-rw-r--r--   2 root supergroup  ... /usr/hive/warehouse/grades/grades.csv
</pre>

The table we just created should be accessible from all nodes, let's
verify that now:
```bash
docker-compose exec worker2 bash
hive
```
```sql
SELECT * FROM grades;
```
You should be able to see the same table.
### Spark

Open up [Spark Master Web UI (localhost:8089)](http://localhost:8089/):
<pre>
Workers (2)
Worker Id	Address	State	Cores	Memory
worker-timestamp-172.28.1.3-8882	172.28.1.3:8882	ALIVE	2 (0 Used)	1024.0 MB (0.0 B Used)
worker-timestamp-172.28.1.2-8881	172.28.1.2:8881	ALIVE	2 (0 Used)	1024.0 MB (0.0 B Used)
</pre>
, also worker UIs at  [localhost:8081](http://localhost:8081/)
and  [localhost:8082](http://localhost:8082/). All those pages should be
accessible.

Then there's also Spark History server running at
[localhost:18080](http://localhost:18080/) - every time you run Spark jobs, you
will see them here.

History Server includes REST API at
[localhost:18080/api/v1/applications](http://localhost:18080/api/v1/applications).
This is a mirror of everything on the main page, only in JSON format.

Let's run some sample jobs now:
```bash
docker-compose exec master bash
run-example SparkPi 10
#, or you can do the same via spark-submit:
spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --deploy-mode cluster \
    --driver-memory 2g \
    --executor-memory 1g \
    --executor-cores 1 \
    $SPARK_HOME/examples/jars/spark-examples*.jar \
    10
```
<pre>
INFO spark.SparkContext: Running Spark version 3.0.0
INFO spark.SparkContext: Submitted application: Spark Pi
..
INFO client.RMProxy: Connecting to ResourceManager at master/172.28.1.1:8032
INFO yarn.Client: Requesting a new application from cluster with 2 NodeManagers
...
INFO yarn.Client: Application report for application_1567375394688_0001 (state: ACCEPTED)
...
INFO yarn.Client: Application report for application_1567375394688_0001 (state: RUNNING)
...
INFO scheduler.DAGScheduler: Job 0 finished: reduce at SparkPi.scala:38, took 1.102882 s
Pi is roughly 3.138915138915139
...
INFO util.ShutdownHookManager: Deleting directory /tmp/spark-81ea2c22-d96e-4d7c-a8d7-9240d8eb22ce
</pre>

Spark has 3 interactive shells: spark-shell to code in Scala,
pyspark for Python and sparkR for R. Let's try them all out:
```bash
hadoop fs -put /data/grades.csv /
spark-shell
```
```scala
spark.range(1000 * 1000 * 1000).count()

val df = spark.read.format("csv").option("header", "true").load("/grades.csv")
df.show()

df.createOrReplaceTempView("df")
spark.sql("SHOW TABLES").show()
spark.sql("SELECT * FROM df WHERE Final > 50").show()

//TODO SELECT TABLE from hive - not working for now.
spark.sql("SELECT * FROM grades").show()
```
<pre>
Spark context Web UI available at http://localhost:4040
Spark context available as 'sc' (master = yarn, app id = application_N).
Spark session available as 'spark'.

res0: Long = 1000000000

df: org.apache.spark.sql.DataFrame = [Last name: string, First name: string ... 7 more fields]

+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|Last name|First name|        SSN|Test1|Test2|Test3|Test4|Final|Grade|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|  Alfalfa|  Aloysius|123-45-6789|   40|   90|  100|   83|   49|   D-|
...
|Heffalump|    Harvey|632-79-9439|   30|    1|   20|   30|   40|    C|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+

+--------+---------+-----------+
|database|tableName|isTemporary|
+--------+---------+-----------+
|        |       df|       true|
+--------+---------+-----------+

+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|Last name|First name|        SSN|Test1|Test2|Test3|Test4|Final|Grade|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
|  Airpump|    Andrew|223-45-6789|   49|    1|   90|  100|   83|    A|
|   Backus|       Jim|143-12-1234|   48|    1|   97|   96|   97|   A+|
| Elephant|       Ima|456-71-9012|   45|    1|   78|   88|   77|   B-|
| Franklin|     Benny|234-56-2890|   50|    1|   90|   80|   90|   B-|
+---------+----------+-----------+-----+-----+-----+-----+-----+-----+
</pre>
Ctrl+D out of Scala shell now.

```bash
pyspark
```
```python
spark.range(1000 * 1000 * 1000).count()

df = spark.read.format('csv').option('header', 'true').load('/grades.csv')
df.show()

df.createOrReplaceTempView('df')
spark.sql('SHOW TABLES').show()
spark.sql('SELECT * FROM df WHERE Final > 50').show()

# TODO SELECT TABLE from hive - not working for now.
spark.sql('SELECT * FROM grades').show()
```
<pre>
1000000000

$same_tables_as_above
</pre>
Ctrl+D out of PySpark.

```bash
sparkR
```
```R
df <- as.DataFrame(list("One", "Two", "Three", "Four"), "This is as example")
head(df)

df <- read.df("/grades.csv", "csv", header="true")
head(df)
```
<pre>
  This is as example
1                One
2                Two
3              Three
4               Four

$same_tables_as_above
</pre>

* Amazon S3

From Hadoop:
```bash
hadoop fs -Dfs.s3a.impl="org.apache.hadoop.fs.s3a.S3AFileSystem" -Dfs.s3a.access.key="classified" -Dfs.s3a.secret.key="classified" -ls "s3a://bucket"
```

Then from PySpark:

```python
sc._jsc.hadoopConfiguration().set('fs.s3a.impl', 'org.apache.hadoop.fs.s3a.S3AFileSystem')
sc._jsc.hadoopConfiguration().set('fs.s3a.access.key', 'classified')
sc._jsc.hadoopConfiguration().set('fs.s3a.secret.key', 'classified')

df = spark.read.format('csv').option('header', 'true').option('sep', '\t').load('s3a://bucket/tabseparated_withheader.tsv')
df.show(5)
```

None of the commands above stores your credentials anywhere
(i.e. as soon as you'd shut down the cluster your creds are safe). More
persistent ways of storing the credentials are out of scope of this
readme.
  
