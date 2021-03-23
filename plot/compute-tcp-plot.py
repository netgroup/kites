#!/usr/bin/python

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sys
import os
import re

cni = sys.argv[1]
N = sys.argv[2]
kites_home = "/vagrant/ext/kites/"

total_thr = None
tests_path =  os.path.join(kites_home, "tests")
cni_eval = []


with os.scandir(tests_path) as listOfEntries:
    for entry_cni in listOfEntries:
        if entry_cni.is_dir():
            cni=entry_cni.name
            cni_eval.append(entry_cni.name)
            cni_tests_path = os.path.join(kites_home, "tests", cni)
            EXP_N = 0
            total = None
            info_columns = None
            with os.scandir(cni_tests_path) as listOfEntries:
                for entry in listOfEntries:
                    if entry.is_dir():
                        exp_match = re.match(r'^exp-(\d+)$', entry.name)
                        if exp_match:
                            exp_n = exp_match.groups()[0]
                            id_exp = entry.name
                            f_name = 'cpu-usage-{}-TCP.csv'.format(cni)
                            path = os.path.join(kites_home, "tests", cni, id_exp, f_name)
                            df = pd.read_csv(path)
                            indexNames = df[df['TCP-CONFIG'] == 'tcp-config'].index
                            current = df.drop(indexNames)
                            if total is None:
                                info_columns = current.iloc[:, 0:4]
                            # take the values
                            current = current.iloc[:, 4:9]
                            print(current)
                            # take the sum
                            if total is not None:
                                total = (total.astype(float) + current.astype(float))
                            else:
                                total = current.astype(float)
                            EXP_N = EXP_N + 1

            total = total/EXP_N           
            total = pd.concat([info_columns, total], axis=1)
            total.columns = total.columns.str.replace(' ', '')
            total['TEST_TYPE'] = total['TEST_TYPE'].str.replace(' ', '')
            total['CONFIG'] = total['CONFIG'].str.replace(' ', '')
            total['TCP-CONFIG'] = total['TCP-CONFIG'].str.replace(' ', '')
            # print(total)
            tcp_group = total.groupby(['TCP-CONFIG'])

            final_rows = []
            final= None
            for tcp_config_name, tcp_df in tcp_group:
                # tcp_config_name = POD o NO_POD
                rows = []
                config_group = tcp_df.groupby(['CONFIG'])
                for config, test_df in config_group:
                    # print(config)
                    # print(test_df)
                    tcp_rows = []
                    cpuoth_rows = []
                    for minion_i in range(1, int(N)+1, 1):
                        for minion_j in range(1, int(N)+1, 1):
                            if (minion_i == minion_j):
                                string_name = 'k8s-minion-{}'.format(minion_i)
                            else:
                                string_name = 'k8s-minion-{}TOk8s-minion-{}'.format(minion_i, minion_j)
                            row_conf = test_df[test_df['TEST_TYPE'] == string_name].index
                            if not row_conf.empty:
                                if (config =="diffnode" and minion_i != minion_j ) or ((config == "samepod") and minion_i == minion_j) or ((config == "samenode") and minion_i == minion_j and test_df.loc[row_conf, "TEST_TYPE"].item() == string_name):
                                    col_master = "cpu-from-master"
                                    col_tx = "cpu-from-minion-"+str(minion_i)
                                    col_rx = "cpu-from-minion-"+str(minion_j)
                                    tot_minions = range(1, N+1)
                                    exclude_set = {minion_i, minion_j}
                                    minion_oth = (list(num for num in tot_minions if num not in exclude_set))
                                    for i in range(0, len(minion_oth)):  
                                        minion_oth_name = minion_oth[i]
                                        # print(minion_oth_name)
                                        col_oth = "cpu-from-minion-"+str(minion_oth_name)
                                        cpu_oth = test_df.loc[row_conf, col_oth]
                                        # print(cpu_oth)
                                        cpuoth_rows.append([cpu_oth.item()])
                                    cpuoth_df = pd.DataFrame(cpuoth_rows,
                                                    columns=["cpu_oth"])
                                    cpu_oth = cpuoth_df["cpu_oth"].mean().item()
                                    thr = test_df.loc[row_conf, "throughput"].item()

                                    cpu_tx = test_df.loc[row_conf, col_tx]
                                    cpu_rx = test_df.loc[row_conf, col_rx]
                                    cpu_master = test_df.loc[row_conf, col_master]
                                    tcp_rows.append([tcp_config_name, config, thr,
                                                    cpu_tx.item(), cpu_rx.item(), cpu_master.item(), cpu_oth])
                    pps_diffnodes = pd.DataFrame(tcp_rows,
                                                    columns=["tcp-config", "config", "thr", "cpu_tx", "cpu_rx", "cpu_master", "cpu_oth"])
                    # print(pps_diffnodes)
                    thr_avg = pps_diffnodes["thr"].mean().item()
                    cpu_rx_avg = pps_diffnodes["cpu_rx"].mean().item()
                    cpu_tx_avg = pps_diffnodes["cpu_tx"].mean().item()
                    cpu_master_avg = pps_diffnodes["cpu_master"].mean().item()
                    cpu_oth_avg = pps_diffnodes["cpu_oth"].mean().item()

                    rows.append([tcp_config_name, config, thr_avg,
                                                    cpu_tx_avg, cpu_rx_avg, cpu_master_avg, cpu_oth_avg ])

                diffnode = pd.DataFrame(
                    rows, columns=["TCP-CONFIG", "config", "Throughput", "cpu_tx", "cpu_rx", "cpu_master", "cpu_oth"])
                # print(diffnode)

                if final is not None:
                    final= final.append(diffnode, ignore_index=True)
                else:
                    final = diffnode

            row_conf = test_df[test_df['TEST_TYPE'] == string_name].index   
            pod_index= final[final['TCP-CONFIG'] == "POD"].index
            df_pod= final.iloc[pod_index,:]

            # PLOT FOR POD TO POD COMMUNICATION: CPU CONSUMPTION CNI
            plt.figure(figsize=(20,15))
            plt.ylim((0, 110)) 
            plt.grid(axis='y')
            plt.xlabel("Pod to Pod")
            plt.title("CPU consumption of TCP traffic - "+cni+"", fontsize=20)
            # set height of bar
            cpu_tx = df_pod["cpu_tx"]
            cpu_rx = df_pod["cpu_rx"]
            cpu_master = df_pod["cpu_master"]
            cpu_oth = df_pod["cpu_oth"]
            # set width of bar
            barWidth = 0.20
            # # Set position of bar on X axis
            r1 = np.arange(len(cpu_tx))
            r2 = [x + barWidth for x in r1]
            r3 = [x + barWidth for x in r2]
            r4 = [x + barWidth for x in r3]
            # # Make the plot
            plt.bar(r1, cpu_tx, color='red', width=barWidth, edgecolor='white', label='cpu_tx', zorder=3)
            plt.bar(r2, cpu_rx, color='xkcd:royal blue', width=barWidth, edgecolor='white', label='cpu_rx', zorder=3)
            plt.bar(r3, cpu_master, color='green', width=barWidth, edgecolor='white', label='cpu_master', zorder=3)
            plt.bar(r4, cpu_oth, color='xkcd:goldenrod', width=barWidth, edgecolor='white', label='cpu_oth', zorder=3)
            # # Add xticks on the middle of the group bars
            labels = ['diffnode', 'samenode', 'samepod']
            plt.xticks([r + barWidth for r in np.arange(barWidth/2, 3)], labels, fontsize=15)
            # # Create legend & Show graphic
            plt.legend(fontsize=10)
            # plt.show()


            # Save throughput of cni on a column of total_thr df
            thr_cni_df= df_pod.loc[:, 'Throughput']
            thr_cni_df.name = cni
            if total_thr is not None:
                total_thr= pd.concat([total_thr, thr_cni_df.reindex(total_thr.index)], axis=1)
            else:
                total_thr = thr_cni_df

print(total_thr)

plt.figure(figsize=(20,15))
plt.grid(axis='y', zorder=0)
plt.ylim((0, 35)) 
plt.title("TCP traffic throughput (Gbps)", fontsize=20)

# set height of bar
cni_height = []
for index, cni in enumerate(cni_eval):
    print(index,cni)
    cni_height.append(total_thr.loc[:,cni])
    print(cni_height)   

# set width of bar
barWidth = 0.20
# # Set position of bar on X axis
r_cni = []
r_cni.append(np.arange(3))
for index in range(0, (len(cni_eval) +1), 1):
    r_cni.append(tuple(x + barWidth for x in r_cni[index]))


# # Draw the plot
for index in range(0, (len(cni_eval)), 1):
    print(r_cni[index], cni_height[index])
    plt.bar(r_cni[index], cni_height[index], width=barWidth, edgecolor='white', label=cni_eval[index], zorder=3)

# # Add xticks on the middle of the group bars
labels = ['diffnode', 'samenode', 'samepod']
plt.xticks([r + barWidth for r in np.arange(barWidth/2,3)], labels, fontsize=15)

# # Create legend & Show graphic
plt.legend(fontsize=10)
plt.show()
plt.savefig(os.path.join(cni_tests_path, 'Comparison_'+'TCP.png'))