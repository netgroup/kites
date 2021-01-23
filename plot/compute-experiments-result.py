#!/usr/bin/python

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# cni=sys.argv[1]
# EXP_N=sys.argv[2]
# bytes=sys.argv[3]
# N=sys.argv[4]
# kites_home="/vagrant/ext/kites/"

kites_home = "../"
cni = "weavenet"
EXP_N = 5
byte = 100
N = 3
rep = EXP_N + 1
print(cni)

total = None
for exp_n in range(1, rep, 1):
    # define exp name
    id_exp = 'exp-{}'.format(exp_n)
    file_name = 'cpu-usage-{}-UDP-{}bytes.csv'.format(cni, byte)
    path = os.path.join(kites_home, "tests", cni, id_exp, file_name)
    df = pd.read_csv(path)
    # remove spurious rows
    indexNames = df[df['PPS'] == 'pps'].index
    current = df.drop(indexNames)
    if total is None:
        info_columns = current.iloc[:, [0, 3]]
    # take the values
    current = current.iloc[:, 4:10]
    # take the sum
    if total is not None:
        total = (total.astype(float) + current.astype(float))
    else:
        total = current.astype(float)

total = total/5
# print(total)
print(info_columns)
total = pd.concat([info_columns, total], axis=1)
total.columns = total.columns.str.replace(' ', '')
# print(total)
# df[0] = df[0].str.strip()
total['TEST_TYPE'] = total['TEST_TYPE'].str.replace(' ', '')
# print(total)
pps_grouped = total.groupby(['PPS'])
rows = []

for group_name, pps_df in pps_grouped:
    # print(group_name)
    print(pps_df)
    pps_rows = []
    # filter by TEST_TYPE k8s-minion-XTOk8s-minion-Y
    for minion_i in range(1, N+1, 1):
        for minion_j in range(1, N+1, 1):
            if minion_i != minion_j:
                string_name = 'k8s-minion-{}TOk8s-minion-{}'.format(
                    minion_i, minion_j)
                row_conf = pps_df[pps_df['TEST_TYPE'] == string_name].index
                # print(string_name, row_conf)
                col_tx = "cpu-from-minion-"+str(minion_i)
                col_rx = "cpu-from-minion-"+str(minion_j)

                rxtx = pps_df.loc[row_conf, "rx/tx"].item()
                txedtx = pps_df.loc[row_conf, "txed/totx"].item()

                cpu_tx = pps_df.loc[row_conf, col_tx]
                cpu_rx = pps_df.loc[row_conf, col_rx]

                pps_rows.append([group_name, rxtx, txedtx,
                                 cpu_tx.item(), cpu_rx.item()])

    pps_diffnodes = pd.DataFrame(pps_rows,
                                 columns=["PPS", "rx/tx", "txed/totx", "cpu_tx", "cpu_rx"])
    cpu_rx_avg = pps_diffnodes["cpu_rx"].mean().item()
    cpu_rx_std = pps_diffnodes["cpu_rx"].std().item()
    cpu_tx_avg = pps_diffnodes["cpu_tx"].mean().item()
    cpu_tx_std = pps_diffnodes["cpu_tx"].std().item()
    print(group_name, rxtx, txedtx, cpu_tx_avg, cpu_rx_avg)

    rows.append([group_name, rxtx, txedtx, cpu_tx_avg,
                 cpu_tx_std, cpu_rx_avg, cpu_rx_std])

diffnode = pd.DataFrame(
    rows, columns=["PPS", "rx/tx", "txed/totx", "cpu_tx", "cpu_tx_std", "cpu_rx", "cpu_rx_std"])
print(diffnode)
plt.figure()
errorbar = plt.errorbar(diffnode['PPS'], 'cpu_tx', yerr='cpu_tx_std', data=diffnode)
errorbar_rx = plt.errorbar(diffnode['PPS'], 'cpu_rx', yerr='cpu_rx_std', data=diffnode)
plt.show()
