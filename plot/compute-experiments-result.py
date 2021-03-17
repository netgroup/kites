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
run_test_same = sys.argv[4]
run_test_samenode = sys.argv[5]
run_test_diffnode = sys.argv[6]
kites_home = "/vagrant/ext/kites/"


if run_test_diffnode:
    config_name="diffnode"
elif run_test_same:
    config_name="samepod"
elif run_test_samenode:
    config_name="samenode"

tests_path =  os.path.join(kites_home, "tests")
total_cni = None
total_cpu = None
cni_eval = []

with os.scandir(tests_path) as listOfEntries:
    for entry_cni in listOfEntries:
        if entry_cni.is_dir():
            print(entry_cni)
            cni=entry_cni.name
            cni_eval.append(entry_cni.name)
            cni_tests_path = os.path.join(kites_home, "tests", cni)
            EXP_N = 0
            total = None
            info_columns = None
            with os.scandir(cni_tests_path) as listOfEntries:
                for entry in listOfEntries:
                    print(entry.name)
                    if entry.is_dir():
                        exp_match = re.match(r'^exp-(\d+)$', entry.name)
                        if exp_match:
                            exp_n = exp_match.groups()[0]
                            id_exp = entry.name
                            f_name = 'cpu-usage-{}-UDP-{}bytes.csv'.format(cni, byte)
                            path = os.path.join(kites_home, "tests", cni, id_exp, f_name)
                            df = pd.read_csv(path)
                            indexNames = df[df['PPS'] == 'pps'].index
                            current = df.drop(indexNames)
                            if total is None:
                                info_columns = current.iloc[:, [0,2, 3]]
                            
                            # take the values
                            cols = [0,1,2,3]
                            current = current.drop(current.columns[cols],axis=1)
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
            total['CONFIG'] = total['CONFIG'].str.replace(' ', '')

            pps_grouped = total.groupby(['PPS'], sort=False)

            cpu_col = [col for col in total.columns if re.search('cpu.+-from-minion-1', col)]
            if not cpu_col: cpu_col = ["no"]
            # print(cpu_col)
            for index in range(0, len(cpu_col), 1):
                rows = []
                rows_cpu = []
                for group_name, pps_df in pps_grouped:
                    # print(group_name)
                    pps_rows = []
                    cpus_rows = []
                    cpuoth_rows = []
                    # print(pps_df)
                    config_group = pps_df.groupby(['CONFIG'])
                    for config, test_df in config_group:
                        # filter by TEST_TYPE k8s-minion-XTOk8s-minion-Y
                        for minion_i in range(1, int(N)+1, 1):
                            for minion_j in range(1, int(N)+1, 1):
                                if (minion_i == minion_j and (run_test_same or run_test_samenode)):
                                    string_name = 'k8s-minion-{}'.format(minion_i)
                                    # print(string_name)
                                else:
                                    string_name = 'k8s-minion-{}TOk8s-minion-{}'.format(minion_i, minion_j)
                                row_conf = test_df[test_df['TEST_TYPE'] == string_name].index
                                # print(row_conf)
                                if not row_conf.empty:
                                    if (config =="diffnode" and minion_i != minion_j and run_test_diffnode ) or ((config == "samepod") and minion_i == minion_j and run_test_same) or (config == "samenode" and minion_i == minion_j and test_df.loc[row_conf, "TEST_TYPE"].item() == string_name and run_test_samenode):
                                        col_master = "cpu_avg_master"
                                        col_tx = "cpu_avg_minion-"+str(minion_i)
                                        
                                        col_rx = "cpu_avg_minion-"+str(minion_j)
                                       
                                        tot_minions = range(1, N+1)
                                        exclude_set = {minion_i, minion_j}
                                        minion_oth = (list(num for num in tot_minions if num not in exclude_set))
                                        for i in range(0, len(minion_oth)):  
                                            minion_oth_name = minion_oth[i]
                                            col_oth = "cpu_avg_minion-"+str(minion_oth_name)
                                            cpu_oth = test_df.loc[row_conf, col_oth]
                                            cpuoth_rows.append([cpu_oth.item()])
                                        cpuoth_df = pd.DataFrame(cpuoth_rows,
                                                        columns=["cpu_oth"])
                                        if not cpuoth_df.empty: 
                                            cpu_oth = cpuoth_df["cpu_oth"].mean().item()
                                        else:
                                            cpu_oth = 0
                                        rxtx = test_df.loc[row_conf, "rx/tx"].item() * 100
                                        txedtx = test_df.loc[row_conf, "txed/totx"].item() * 100

                                        cpu_tx = test_df.loc[row_conf, col_tx]
                                        
                                        cpu_rx = test_df.loc[row_conf, col_rx]
                                        
                                        cpu_master = test_df.loc[row_conf, col_master]
                                        pps_rows.append([group_name, rxtx, txedtx,
                                                        cpu_tx.item(), cpu_rx.item(), cpu_master.item(), cpu_oth])

                                        if 'no' not in cpu_col:
                                            col_single_tx = "cpu"+str(index)+"-from-minion-"+str(minion_i)
                                            col_single_rx = "cpu"+str(index)+"-from-minion-"+str(minion_j)
                                            cpu_single_tx = test_df.loc[row_conf, col_single_tx]
                                            cpu_single_rx = test_df.loc[row_conf, col_single_rx]
                                            cpus_rows.append([group_name, rxtx, txedtx, cpu_single_tx.item(), cpu_single_rx.item() ])

                        if (config =="diffnode" and run_test_diffnode ) or ((config == "samepod") and run_test_same) or (config == "samenode" and run_test_samenode):
                            pps_diffnodes = pd.DataFrame(pps_rows,
                                                        columns=["PPS", "rx/tx", "txed/totx", "cpu_tx", "cpu_rx", "cpu_master", "cpu_oth"])
                            # print(pps_diffnodes)

                            cpu_rx_avg = pps_diffnodes["cpu_rx"].mean().item()
                            cpu_rx_std = pps_diffnodes["cpu_rx"].std().item()
                            cpu_tx_avg = pps_diffnodes["cpu_tx"].mean().item()
                            cpu_tx_std = pps_diffnodes["cpu_tx"].std().item()
                            cpu_master_avg = pps_diffnodes["cpu_master"].mean().item()
                            cpu_master_std = pps_diffnodes["cpu_master"].std().item()
                            cpu_oth_avg = pps_diffnodes["cpu_oth"].mean().item()
                            cpu_oth_std = pps_diffnodes["cpu_oth"].std().item()
                            # print(group_name, rxtx, txedtx, cpu_tx_avg, cpu_tx_std, cpu_rx_avg, cpu_rx_std)
                            
                            rows.append([group_name, rxtx, txedtx,
                                        cpu_tx_avg, cpu_tx_std, cpu_rx_avg, cpu_rx_std,
                                            cpu_master_avg, cpu_master_std, cpu_oth_avg, cpu_oth_std])


                            if 'no' not in cpu_col:
                                pps_cpus = pd.DataFrame(cpus_rows,
                                                        columns=["PPS", "rx/tx", "txed/totx", "cpu"+str(index)+"_tx", "cpu"+str(index)+"_rx"])
                                
                                cpu_single_rx_avg = pps_cpus["cpu"+str(index)+"_rx"].mean().item()
                                cpu_single_rx_std = pps_cpus["cpu"+str(index)+"_rx"].std().item()
                                cpu_single_tx_avg = pps_cpus["cpu"+str(index)+"_tx"].mean().item()
                                cpu_single_tx_std = pps_cpus["cpu"+str(index)+"_tx"].std().item()

                                rows_cpu.append([group_name, rxtx, txedtx,
                                            cpu_single_tx_avg, cpu_single_tx_std, cpu_single_rx_avg, cpu_single_rx_std ])

                diffnode = pd.DataFrame(
                    rows, columns=["PPS", "rx/tx", "txed/totx", "cpu_tx", "cpu_tx_std", "cpu_rx", "cpu_rx_std",  "cpu_master", "cpu_master_std", "cpu_oth", "cpu_oth_std"])

                # print(diffnode)
                if index == 0:
                    # Plot average cpu of single cni
                    plt.figure(figsize=(20,15))
                    plt.ylim((0, 110)) 
                    plt.grid(axis='y', zorder=0)

                    plt.xlabel("pps", fontsize=15)
                    plt.title(""+cni+" - "+str(byte)+"bytes - "+config_name+"",fontsize=20)

                    errorbar_cpu_tx = plt.errorbar(
                        diffnode['PPS'], "cpu_tx", yerr="cpu_tx_std", data=diffnode, zorder=3)
                    errorbar_txedtx = plt.errorbar(diffnode['PPS'], 'txed/totx',  data=diffnode, zorder=3)
                    errorbar_cpu_rx = plt.errorbar(
                        diffnode['PPS'], "cpu_rx", yerr="cpu_rx_std", data=diffnode, zorder=3)
                    errorbar_rxtx = plt.errorbar(diffnode['PPS'], 'rx/tx',  data=diffnode, zorder=3)
                    errorbar_cpu_master = plt.errorbar(
                        diffnode['PPS'], 'cpu_master', yerr='cpu_master_std', data=diffnode, zorder=3)
                    errorbar_cpu_oth = plt.errorbar(
                        diffnode['PPS'], 'cpu_oth', yerr='cpu_oth_std', data=diffnode, zorder=3)
                    plt.legend(fontsize=10)
                    plt.show()
                    plt.savefig(os.path.join(cni_tests_path, cni+'_'+str(byte)+'bytes'+str(EXP_N)+'exp.png'))

                    # Save rxtx-txedtotx of cni on a column of total_thr df
                    cni_df = diffnode.loc[:, ['rx/tx','txed/totx']]
                    cni_df.columns = ['rx/tx_'+cni, 'txed/totx_'+cni ]
                    if total_cni is not None:
                        total_cni= pd.concat([total_cni, cni_df.reindex(total_cni.index)], axis=1)
                    else:
                        total_cni = pd.concat([diffnode.loc[:, ['PPS']], cni_df.reindex(diffnode.loc[:, ['PPS']].index)], axis=1)


                if 'no' not in cpu_col:
                    cpudf = pd.DataFrame(
                        rows_cpu, columns=["PPS", "rx/tx", "txed/totx", "cpu"+str(index)+"_tx", "cpu"+str(index)+"_tx_std", "cpu"+str(index)+"_rx", "cpu"+str(index)+"_rx_std"])
                    print(cpudf)
                    if index == 0:
                        total_cpu = cpudf.loc[:, ['PPS', 'rx/tx','txed/totx', "cpu"+str(index)+"_tx", "cpu"+str(index)+"_tx_std", "cpu"+str(index)+"_rx", "cpu"+str(index)+"_rx_std"]]
                        print(total_cpu)
                    else:
                        total_cpu[ "cpu"+str(index)+"_tx" ] = cpudf["cpu"+str(index)+"_tx"]
                        total_cpu[ "cpu"+str(index)+"_tx_std" ] = cpudf["cpu"+str(index)+"_tx_std"]
                        total_cpu[ "cpu"+str(index)+"_rx" ] = cpudf["cpu"+str(index)+"_rx"]
                        total_cpu[ "cpu"+str(index)+"_rx_std" ] = cpudf["cpu"+str(index)+"_rx_std"]
            print(total_cpu)

            if index > 0:
                # Plot single cpu of single cni
                plt.figure(figsize=(20,15))
                plt.ylim((0, 110)) 
                plt.grid(axis='y', zorder=0)

                plt.xlabel("pps", fontsize=15)
                plt.title("Single CPUs.",fontsize=20)

                for cpu_n in range(0, len(cpu_col), 1):
                    print(cpu_n)
                    errorbar_cpu_tx = plt.errorbar(
                        total_cpu['PPS'], "cpu"+str(cpu_n)+"_tx", yerr="cpu"+str(cpu_n)+"_tx_std", data=total_cpu, zorder=3)
                    errorbar_cpu_rx = plt.errorbar(
                        total_cpu['PPS'], "cpu"+str(cpu_n)+"_rx", yerr="cpu"+str(cpu_n)+"_rx_std", data=total_cpu, zorder=3)

                errorbar_rxtx = plt.errorbar(total_cpu['PPS'], 'rx/tx',  data=total_cpu, zorder=3)
                errorbar_txedtx = plt.errorbar(total_cpu['PPS'], 'txed/totx',  data=total_cpu, zorder=3)
                plt.legend(fontsize=10)
                plt.show()
                plt.savefig(os.path.join(cni_tests_path, cni+'_'+str(byte)+'bytes'+str(EXP_N)+'exp_single_cpu.png'))

print(total_cni)

plt.figure(figsize=(20,15))
plt.ylim((85, 101)) 
plt.grid(axis='y', zorder=0)

plt.xlabel("pps", fontsize=15)
plt.title("Comparison "+config_name,fontsize=20)

print(cni_eval)

total_cni['PPS'] = total_cni['PPS'].astype(str)
for cni in cni_eval:
    errorbar_txedtx = plt.errorbar(total_cni['PPS'], 'txed/totx_'+str(cni), data=total_cni, zorder=3)
    # errorbar_rxtx = plt.errorbar(total_cni['PPS'], 'rx/tx_'+str(cni),  data=total_cni, zorder=3)


plt.legend(fontsize=10)
plt.show()