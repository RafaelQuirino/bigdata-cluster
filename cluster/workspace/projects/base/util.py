"""
util.py
This is a useful module with SparkSession and io functions
"""


from config import sparkConf
from pyspark.sql import SparkSession


def read_from_csv (
    spark,
    csv_path : str,
    delimiter : str = ',', 
    options  : list = [
        {'header': 'true'}, 
        {'encoding': 'UTF8'},
        {'inferSchema': 'true'}
    ]
):
    """read_from_csv
    """
    df = spark.read \
        .format("csv") \
        .options(delimiter=delimiter)
    for o in options:
        k = list(o.keys())[0]
        df = df.option(k, o[k])
    df = df.load(csv_path)
    return df


def write_to_csv (
    dataframe,
    path       : str  = '.',
    mode       : str  = 'overwrite',
    partitions : list = [],
    options    : list = [
        {'header': 'true'}, 
        {'encoding': 'UTF8'}
    ]
):
    """write_to_csv
    Write spark dataframe to csv.
    Options for some configuration.
    """
    print(f'Writing CSV files into {path}...')
    d = dataframe.write \
        .partitionBy(*partitions) \
        .mode(mode) \
        .options(delimiter='|')
    for o in options:
        k = list(o.keys())[0]
        d = d.option(k, o[k])
    d.csv(path)
    return True


def read_from_parquet (spark, parquet_path):
    """read_from_parquet
    """
    return spark.read.parquet(parquet_path)


def write_to_parquet (
    dataframe, 
    table_name : str, 
    path : str = '.', 
    mode : str = 'overwrite',
    compression : str = 'snappy',
    partitions : list = []
):
    """write_to_parquet
    """
    print(f'Writing paquet files into {path}/{table_name}.parquet...')
    dataframe.write \
        .partitionBy(*partitions) \
        .mode(mode) \
        .option('encoding', 'UTF8') \
        .option('compression', compression) \
        .parquet(f'{path}/{table_name}.parquet')
    return True