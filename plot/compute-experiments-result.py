#!/usr/bin/python

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sys
import os
import re

cni = sys.argv[1]
byte = sys.argv[2]
N = sys.argv[3]
kites_home = "/vagrant/ext/kites/"

# kites_home = "../"
# cni = "weavenet"
# byte = 100
# N = 3


cni_tests_path = os.path.join(kites_home, "tests", cni)
# cni_tests_path = "c:/Users/carla/Documents/kubernetes-playground/ext/kites/tests/"+cni

EXP_N = 0
total = None
with os.scandir(cni_tests_path) as listOfEntries:
    for entry in listOfEntries:
        if entry.is_dir():
            exp_match = re.match(r'^exp-(\d+)$', entry.name)
            if exp_match:
                exp_n = exp_match.groups()[0]
                id_exp = entry.name
                f_name = 'cpu-usage-{}-UDP-{}bytes.csv'.format(cni, byte)
                path = os.path.join(kites_home, "tests", cni, id_exp, f_name)
                # path = "C:/Users/carla/Documents/kubernetes-playground/ext/kites/tests/"+cni+"/"+id_exp+"/"+f_name+""
                df = pd.read_csv(path)
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
                EXP_N = EXP_N + 1

total = total/EXP_N
# print(total)
# print(info_columns)
total = pd.concat([info_columns, total], axis=1)
total.columns = total.columns.str.replace(' ', '')
total['TEST_TYPE'] = total['TEST_TYPE'].str.replace(' ', '')
# print(total)
pps_grouped = total.groupby(['PPS'])
rows = []

for group_name, pps_df in pps_grouped:
    # print(group_name)
    print(pps_df)
    pps_rows = []
    # filter by TEST_TYPE k8s-minion-XTOk8s-minion-Y
    for minion_i in range(1, int(N)+1, 1):
        for minion_j in range(1, int(N)+1, 1):
            if minion_i != minion_j:
                string_name = 'k8s-minion-{}TOk8s-minion-{}'.format(
                    minion_i, minion_j)
                row_conf = pps_df[pps_df['TEST_TYPE'] == string_name].index
                # print(string_name, row_conf)
                col_tx = "cpu-from-minion-"+str(minion_i)
                col_rx = "cpu-from-minion-"+str(minion_j)
                rxtx = pps_df.loc[row_conf, "rx/tx"].item() * 100
                
                txedtx = pps_df.loc[row_conf, "txed/totx"].item() * 100

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
    # print(group_name, rxtx, txedtx, cpu_tx_avg, cpu_tx_std, cpu_rx_avg, cpu_rx_std)

    rows.append([group_name, rxtx, txedtx, cpu_tx_avg,
                 cpu_tx_std, cpu_rx_avg, cpu_rx_std])

diffnode = pd.DataFrame(
    rows, columns=["PPS", "rx/tx", "txed/totx", "cpu_tx", "cpu_tx_std", "cpu_rx", "cpu_rx_std"])

# print(diffnode)
plt.figure()

plt.xlabel("pps")
plt.title(""+cni+" - "+str(byte)+"bytes")

errorbar_cpu_tx = plt.errorbar(
    diffnode['PPS'], 'cpu_tx', yerr='cpu_tx_std', data=diffnode)
errorbar_txedtx = plt.errorbar(diffnode['PPS'], 'txed/totx',  data=diffnode)
errorbar_cpu_rx = plt.errorbar(
    diffnode['PPS'], 'cpu_rx', yerr='cpu_rx_std', data=diffnode)
errorbar_rxtx = plt.errorbar(diffnode['PPS'], 'rx/tx',  data=diffnode)
plt.legend((errorbar_cpu_tx, errorbar_cpu_rx, errorbar_txedtx, errorbar_rxtx), ('cpu_tx', 'cpu_rx', 'txed/totx', 'rx/tx'))
# plt.legend()
plt.show()
plt.savefig(cni_tests_path+'/'+cni+'_'+str(byte)+'bytes.png')
