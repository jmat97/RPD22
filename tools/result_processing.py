#!/usr/bin/python3
# Copyright (C) 2022  AGH University of Science and Technology
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import io, wfdb, csv, os
import numpy as np
import matplotlib.pyplot as plt

def write_recording_to_file(record_num):
    record_path = 'tools/mit_bih_arrhythmia_database/{}'.format(record_num)
    record = wfdb.rdrecord(record_path)
    record.adc(inplace=True)
    with io.open('sim/stimulus/{}'.format(record_num) +'.csv', mode='w', newline='') as file:
        writer = csv.writer(file)
        for i in range(record.sig_len):
            writer.writerow([i, record.d_signal[i][0]])

def write_all_recordings_to_file():
    mitbih_records = wfdb.get_record_list('mitdb')
    for i in range(len(mitbih_records)):
        write_recording_to_file(mitbih_records[i])

def read_results_from_file(record_num):
    result_path = 'results/{}'.format(record_num)
    results = np.array([], dtype=np.uint32)
    with io.open(result_path +'.txt', mode='r', newline='') as file:
        reader = csv.reader(file)
        for i in reader:
            results = np.append(results,  i[1])
    return results.astype(np.int32)


def unique(list1):
    # insert the list to the set
    list_set = set(list1)
    # convert the set to the list
    return (list(list_set))

def read_annotations(record_num):
    record_path = 'tools/mit_bih_arrhythmia_database/{}'.format(record_num)
    ann = wfdb.rdann(record_path, 'atr')
    unique_symbols = unique(ann.symbol)# .sample

    print(record_num)
    print(unique_symbols)
    total_count = 0
    for i in unique_symbols:
        symbol_count = ann.symbol.count(i)
        print('symbol: {}\tcount: {}'.format(i,symbol_count))
        total_count += symbol_count


def clear_nonbeat(samples, symbols):
    nonbeat_indexes = []
    for i in range(len(symbols)):
        if is_nonbeat(symbols[i]):
            nonbeat_indexes.append(i)
    #print(nonbeat_indexes)
    samples = np.delete(samples, nonbeat_indexes)
    symbols = np.delete(symbols, nonbeat_indexes)
    return samples, symbols

def align_ann_array(samples,symbols):
    while samples[0] < (1080+32):
        #print("dupa{}".format(samples[0]))
        samples = np.delete(samples, 0)
        symbols = np.delete(symbols, 0)
    return samples, symbols

def is_nonbeat(symbol):
    nonbeat_ann = ["+","[","!","]", "x", "(", ")", "p", "t", "u", "`", "'", "^", "|", "~", "T", "*", "D", "=", '"', "@"]
    if symbol in nonbeat_ann:
        #print("{}".format(symbol))
        return 1
    return 0

def remove_arr_indexes(samples,symbols,indexes):
    samples = np.delete(samples, indexes)
    symbols = np.delete(symbols, indexes)
    return samples, symbols

def compare_results(ref_ann, r_peaks):
    TP = 0
    TP_indexes_ref = []
    TP_indexes = []
    FN_indexes = []
    for i in range(len(ref_ann)):
        discrepancy = 0
        j=0
        curr_ann_sample_num =  ref_ann[i]
        while j < len(r_peaks):
            discrepancy = curr_ann_sample_num - r_peaks[j]
            if abs(discrepancy) <= (54):
                #print("hurra:i:{},\tref_num:{},j:\t{},\talg_num{}".format(i,curr_ann_sample_num, j, r_peaks[j]))
                TP_indexes.append(j)
                TP_indexes_ref.append(i)
                break
            j += 1
        if(j == len(r_peaks)):
            #print("haha: {}".format(curr_ann_sample_num))
            FN_indexes.append(i)
    TP = len(TP_indexes_ref)
    FP = len(np.delete(r_peaks,TP_indexes))
    FN = len(np.delete(ref_ann,TP_indexes_ref))
    return TP,FP,FN

def prepare_results(rec):
    record_path = 'tools/mit_bih_arrhythmia_database/{}'.format(rec)
    ann = wfdb.rdann(record_path, 'atr')
    ann_samples_orig = ann.sample
    ann_symbols_orig = ann.symbol
    ann_samples, ann_symbols =  clear_nonbeat(ann_samples_orig,ann_symbols_orig)
    #ann_samples, ann_symbols =  align_ann_array(ann_samples_orig, ann_symbols_orig)
    return ann_samples, ann_symbols

def evaluate_rec(rec_name):
    output_res = np.array([], dtype=np.uint32)
    output_res = read_results_from_file(rec_name)
    ann_samples, ann_symbols = prepare_results(rec_name)

    #print(ann_samples)
    #print ("REF:{} ALG:{}".format(len(ann_samples),len(output_res)))
    TP,FP,FN = compare_results(ann_samples,output_res)
    DER = 100*(FP + FN)/(TP + FN)
    print("{0}-> TP:{1}\tFP:{2}\tFN:{3}\tDER:{4:.2f}%".format(rec_name,TP,FP,FN,DER))
    return TP,FP,FN, DER
    # plt.plot(output_res, 'ro')
    # plt.ylabel('tsa')
    # plt.plot(ann_samples, 'go')
    # plt.ylabel('some numbers')
    # plt.show()
def evaluate_all_rec():
    mitbih_records = wfdb.get_record_list('mitdb')
    with io.open('results/summary' +'.csv', mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(["record_num","TP","FP","FN","DER"])
        for i in range(len(mitbih_records)):
            record_num = mitbih_records[i]
            TP,FP,FN, DER = evaluate_rec(record_num)
            writer.writerow("{0},{1},{2},{3},{4:.2f}".format(record_num,TP,FP,FN,DER))


def download_db():
    #wfdb.io.set_db_index_url(db_index_url='https://physionet.org/files/mitdb/1.0.0/')
    db_path = os.getcwd()  + "/tools/mit_bih_arrhythmia_database/"
    wfdb.dl_database("mitdb",dl_dir =db_path)

if __name__ == "__main__":
    # record = wfdb.rdrecord(path)
    # write_all_recordings_to_file()
    # print(output_res)
    #mitbih_records = wfdb.get_record_list('mitdb')
    # for i in range(len(mitbih_records)):


    evaluate_all_rec()
    #download_db()
    #read_annotations(101)
    #evaluate_rec(101)
    # print(ann_samples)
    # plt.plot(output_res, 'ro')
    # plt.ylabel('tsa')
    # plt.plot(ann_samples, 'go')
    # plt.ylabel('some numbers')
    # plt.show()
    # for i in range(ann.ann_len):
    #         print('i:{}\tsample:{}\tann:{}'.format(i, ann.sample[i], ann.symbol[i]))


