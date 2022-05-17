from pyspark.sql import SparkSession

master = 'yarn'
appName = 'Test App'
driverMemory = '1g'
executorMemory = '1g'
executorCores = '1'

spark = SparkSession.builder \
        .master(master) \
        .appName(appName) \
        .config("spark.driver.memory", driverMemory) \
        .config("spark.executor.memory", executorMemory) \
        .config("spark.executor.cores", executorCores) \
        .enableHiveSupport() \
        .getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

df = spark.sql('''
SELECT *
FROM grades
''')
df.show()
