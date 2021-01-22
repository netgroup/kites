#!/usr/bin/python

import pandas as pd
import numpy as np
import sys

# cni=sys.argv[1]
# EXP_N=sys.argv[2]
# bytes=sys.argv[3]
# kites_home="/vagrant/ext/kites/"

kites_home="c:/Users/carla/Documents/kubernetes-playground/ext/kites/"
cni="weavenet"
EXP_N=5
byte=100

rep= EXP_N + 1
print(cni)

# initialize total with the first experiment
total= pd.read_csv(kites_home + "tests/"+ cni +"/exp-1/cpu-usage-" + cni + "-UDP-" + str(byte) +"bytes.csv")
# print(total)
# remove spurious rows and take the values
indexNames = total[ total['PPS'] == 'pps' ].index
total= total.drop(indexNames)
total = total.iloc[:, 4:10]

for exp_n in range(2, rep, 1):
    #define exp name
    id_exp="exp-"+str(exp_n)
    url=(kites_home+"tests/"+ cni +"/"+ id_exp +"/cpu-usage-" + cni + "-UDP-" + str(byte) + "bytes.csv")
    df = pd.read_csv(url)
    # remove spurious rows
    indexNames = df[ df['PPS'] == 'pps' ].index
    current = df.drop(indexNames)
    # take the values
    current = current.iloc[:, 4:10]
    # take the sum
    total = (total.astype(float) + current.astype(float))

total = total/5
print(total)

