#!/bin/bash

sudo rm -rf hue/metadata
mkdir hue/metadata
sudo rm -rf hive/metadata
mkdir hive/metadata
sudo rm -rf master/airflow/*
sudo rm -rf master/flags/*
sudo rm -rf master/dfs/*
sudo rm -rf worker1/dfs/*
sudo rm -rf worker2/dfs/*
