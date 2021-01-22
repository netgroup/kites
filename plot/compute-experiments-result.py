#!/usr/bin/python

import pandas as pd
import numpy as np
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
pps_min = 13000
pps_max = 20000
pps_inc = 500
N = 3
rep = EXP_N + 1
print(cni)

total = None
for exp_n in range(1, rep, 1):
    # define exp name
    id_exp = "exp-"+str(exp_n)
    file_name = "cpu-usage-" + cni + "-UDP-" + str(byte) + "bytes.csv"
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
print(total)
print(info_columns)
total = pd.concat([info_columns, total], axis=1)
total.columns = total.columns.str.replace(' ', '')
print(total)
# df[0] = df[0].str.strip()
total['TEST_TYPE'] = total['TEST_TYPE'].str.replace(' ', '')
print(total)


rows = []
for pps in range(pps_min, pps_max+pps_inc, pps_inc):
    print(pps)
    index_pps = total[total['PPS'] == ''+str(pps)+''].index
    print(index_pps)
    pps_df = total.loc[index_pps]
    print(pps_df)
    print(list(pps_df.columns.values))
    n = 1
    cpu_tx_sum = 0
    cpu_rx_sum = 0
    for minion_i in range(1, N+1, 1):
        for minion_j in range(1, N+1, 1):
            if minion_i != minion_j:
                string_name = 'k8s-minion-' + \
                    str(minion_i) + 'TOk8s-minion-' + str(minion_j) + ''
                print(string_name)
                row_conf = pps_df[pps_df['TEST_TYPE'] == 'k8s-minion-' +
                                  str(minion_i) + 'TOk8s-minion-' + str(minion_j) + ''].index
                col_tx = "cpu-from-minion-"+str(minion_i)
                col_rx = "cpu-from-minion-"+str(minion_j)

                rxtx = pps_df.loc[row_conf, "rx/tx"].item()
                txedtx = pps_df.loc[row_conf, "txed/totx"].item()

                cpu_tx = pps_df.loc[row_conf, col_tx]
                cpu_tx_sum = ((cpu_tx_sum + cpu_tx)).item()
                cpu_rx = pps_df.loc[row_conf, col_rx]
                cpu_rx_sum = ((cpu_rx_sum + cpu_rx)).item()
                n = n+1

    cpu_rx_avg = cpu_rx_sum/n
    cpu_tx_avg = cpu_tx_sum/n
    rows.append([pps, rxtx, txedtx, cpu_tx_avg, cpu_rx_avg])

diffnode = pd.DataFrame(
    rows, columns=["PPS", "rx/tx", "txed/totx", "cpu_tx", "cpu_rx"])
print(diffnode)

#boxplot = df.boxplot()
#fig = boxplot.get_figure()
#fig.savefig("output.png")