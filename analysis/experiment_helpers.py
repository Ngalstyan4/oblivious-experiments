import pandas as pd
import numpy as np
import plotly.express as px
from datetime import datetime
import os


# def get_components(m):
#         if m.lock_minpf_time:
#             print("MinPF (delayed hits) =", m.lock_minpf_time, ", Total time =", m.wall_clock_time)
#             print((m.page_fault_time - m.swap_in_time - m.lock_minpf_time) / m.num_total_faults)
#         return (m.user_time,
#                 m.evict_time,
#                 m.swap_in_time,
#                 m.lock_minpf_time or 0,
#                 m.tpo_pf_time or 0,
#                 m.page_fault_time - m.swap_in_time - (m.lock_minpf_time or 0) - (m.tpo_pf_time or 0),
#                 m.wall_clock_time - m.user_time - m.evict_time - m.page_fault_time)

#     linux_c = get_components(linux_m)
#     tape_c = get_components(tape_m)
#     names = ("user time", "evictions", "swapin I/O time", "delayed hit I/O time", "3po pf time", "other pf time", "other")



def get_components_of_runtime(table, name="unnamed"):
    sub_tbl = table[["User Time",
                     "Eviction Time",
                     "Swapin I/O time",
                     "Delayed hit I/O time",
                     "3PO PF time",
                     "Other PF time",
                     "Other"
#                      "Baseline minor PF Time",
#                      "Extra Minor PF Time",
#                      ,
#                      "Extra User Time",
                                     ]] / 1e6
    sub_tbl["Experiment Name"] = table["Experiment Name"]
    fig = px.area(sub_tbl, title='Components of runtime(%s)'%name,
                  color_discrete_sequence=['blue', 'orangered',  '#00cc96', 'red', 'purple', 'brown', 'hotpink'],
                  animation_frame="Experiment Name")
    fig.update_layout(
        xaxis_title="Ratio",
        yaxis_title="Time(seconds)",
    )
 #   fig.add_trace(px.line(table["Measured(wallclock) runtime"]).data[0])
  #  fig.add_trace(px.line(table["sys+usr"] / 1e6).data[0])

    def anno(text, posx = 1.1, posy=0.32):
        dy = -0.04
        if anno.counter > 0:
            posx += 0.15
        fig.add_annotation(text=text,
              xref="paper", yref="paper",
              x=posx, y=posy + dy * anno.counter, showarrow=False)
        anno.counter+= 1
    anno.counter = 0

    #anno("Workload constants:")
    #anno("Baseline System Time(s): %.2f" % (table["Baseline System Time"].values[0]/1e6))
    #anno("Baseline App Time(s): %.2f" % (table["Baseline App Time(us)"].values[0] / 1e6))
    #anno("Baseline Minor PF Time(us): %.2f" % table["Baseline Single Minor PF Time(us)"].values[0])

    return fig

def get_experiment_data(EXPERIMENT_TYPES, ind, experiment_name, experiment_dir):
    ind = str(ind)
    # get experiment data
    get_table = lambda experiment_type, table: pd.read_csv("%s/%s/%s/%s/%s_results.csv" % (experiment_dir, experiment_name, experiment_type, ind, table))
    all_data = pd.DataFrame()
    for exp_type in EXPERIMENT_TYPES:
        cgroup = get_table(exp_type, "cgroup").set_index("RATIO")
        ftrace = get_table(exp_type, "ftrace").set_index("RATIO")

        # in multithreaded apps info is collected per cpu, so let's average it
        # N.B. todo:: does not work well for everything. would be good to add up number of
        # faults,
        ftrace = ftrace.groupby(["RATIO"]).sum()
        time_and_swap = get_table(exp_type, "time_and_swap").set_index("RATIO")
        experiment_final = ftrace.join(cgroup).join(time_and_swap)
        experiment_final["EXP"] = exp_type
        all_data = all_data.append(experiment_final)

    """
    Column Legend
    SWAPIN_* : comes from ftrace, tracks calls to swapin_readahead function and closely measures # of major page faults
    EVICT_*  : comes from ftrace, tracks calls to try_to_free_mem_cgroup_pages. is not used ......
    NUM_FAULTS,NUM_MAJOR_FAULTS: comes from cgroup memory.stat, counts major+minor fault counts
    USER, SYSTEM, WALLCLOCK: from /usr/bin/time
    PAGES_EVICTED,PAGES_SWAPPED_IN : comes from fastswap NIC counters
    """
    return all_data


def augment_tables(tbl, filter_raw=True):

    


    
    def per_exp_baseline(exp, measurement_col):
        # for each experiment, val is value of `measurement` under 100% local memory
        val = tbl[(tbl.index == 100) & (tbl["EXP"] == exp)][measurement_col].values[0]
        return val

    tbl["Single Minor PF time(us)"]       = tbl["PAGE_FAULT_TIME"] / tbl["PAGE_FAULT_HIT"]

    for exp in tbl["EXP"].unique():

        # all uppercase names are filtered in the end. Also, "Experiment Name" is more
        # readable for plot sliders
        tbl.loc[tbl["EXP"] == exp, "Experiment Name"] = exp

        # set appropriate baseline column, filter rows by exp type(tbl["EXP"] == exp)
        tbl.loc[tbl["EXP"] == exp, "Baseline System Time"] = per_exp_baseline(exp, "SYSTEM") * 1e6
        tbl.loc[tbl["EXP"] == exp, "Baseline User Time"] =   per_exp_baseline(exp, "USER") * 1e6
        tbl.loc[tbl["EXP"] == exp, "Baseline Single Minor PF Time(us)"] =   per_exp_baseline(exp, "Single Minor PF time(us)")

#     MeasurementTuple = collections.namedtuple("MeasurementTuple", ("ratio",
#                                                                "num_major_faults",
#                                                                "num_total_faults",
#                                                                "user_time",
#                                                                "wall_clock_time",
#                                                                "pages_evicted",
#                                                                "pages_swapped_in",
#                                                                "page_fault_time",
#                                                                "swap_in_time",
#                                                                "evict_time",
#                                                                "lock_minpf_time",
#                                                                "tpo_pf_time"))
#             self.by_ratio[ratio] = Measurement(ratio,
#                                                int(cgroup["NUM_MAJOR_FAULTS"]),
#                                                int(cgroup["NUM_FAULTS"]),
#                                                time_to_secs(stats["USER"]),
#                                                time_to_secs(stats["WALLCLOCK"]),
#                                                int(stats["PAGES_EVICTED"]),
#                                                int(stats["PAGES_SWAPPED_IN"]),
#                                                micros_empty_to_secs(ftrace["PAGE_FAULT_TIME"]),
#                                                micros_empty_to_secs(ftrace["SWAPIN_TIME"]),
#                                                micros_empty_to_secs(ftrace["EVICT_TIME"]),
#                                                micros_empty_to_secs(ftrace["LOCK_MINPF_TIME"]) if "LOCK_MINPF_TIME" in ftrace else None,
#                                                micros_empty_to_secs(ftrace["3PO_PF_TIME"]) if "3PO_PF_TIME" in ftrace else None)

    def to_seconds(a):
        pt = datetime.strptime(a,'%M:%S.%f')
        total_seconds = pt.microsecond * 1e-6 + pt.second + pt.minute*60 + pt.hour*3600
        return total_seconds

    tbl["Evictions"]               = tbl["PAGES_EVICTED"].fillna(0)

    tbl["Major Page Faults"]       = tbl["NUM_MAJOR_FAULTS"].fillna(0)
    tbl["Total Page Faults"]       = tbl["NUM_FAULTS"].fillna(0)
    tbl["Minor Page Faults"]       = tbl["NUM_FAULTS"] - tbl["NUM_MAJOR_FAULTS"]
    tbl["PF Time(us)"]             = tbl["PAGE_FAULT_TIME"].fillna(0)
    tbl["Eviction Time"]           = tbl['EVICT_TIME'].fillna(0)
    tbl["Swapin I/O time"]         = tbl["SWAPIN_TIME"].fillna(0)
    tbl["Delayed hit I/O time"]    = tbl["LOCK_MINPF_TIME"].fillna(0)
    tbl["3PO PF time"]             = tbl["3PO_PF_TIME"].fillna(0)

    tbl["Other PF time"]           = tbl["PF Time(us)"]-tbl["Swapin I/O time"]-tbl["Delayed hit I/O time"]-tbl["3PO PF time"]
    tbl["Other"]                   = tbl["WALLCLOCK"].map(to_seconds) * 1e6-tbl["USER"] * 1e6 -tbl["Eviction Time"] - tbl["PF Time(us)"]
    tbl["Other"]   = tbl["Other"].clip(0)
#print(([ tbl["WALLCLOCK"].map(to_seconds), tbl["USER"], tbl["Eviction Time"], tbl["PF Time(us)"]]))
    


    # todo:: sth wrong with Sync time since:
   #    it is called by do_page_fault and its time should be included in minor fault time
   #    it is not present in linux_prefetching baseline
   #    ----- so, extra minor PF time should be AT LEAST sync time
   # conclusion does not hold since at times SYNC time is 0.6 sec and extra minor fault time is 0.5
   # tbl["Tape Sync Time(us)"]      = tbl["SYNC_TIME"].fillna(0)
    tbl["Baseline minor PF Time"]  = tbl["Minor Page Faults"] * tbl["Baseline Single Minor PF Time(us)"]

#     tbl["Extra Minor PF Time"] = (tbl["PF Time(us)"] - tbl["Major PF Time"] -  tbl["Baseline minor PF Time"]).clip(0)

    tbl["Extra User Time"]         = tbl["USER"] * 1e6 - tbl["Baseline User Time"]
    tbl["User Time"]         = tbl["USER"] * 1e6


#     tbl["System Overhead"]         = tbl["Baseline minor PF Time"] + \
#                                        tbl["Extra Minor PF Time"] + \
#                                        tbl["Eviction Time"] + \
#                                        tbl["Major PF Time"]

#     tbl["Total System Time"]       = tbl["System Overhead"] + \
#                                        tbl["Baseline System Time"]


    tbl["Measured(wallclock) runtime"] = tbl["WALLCLOCK"].map(to_seconds)

    tbl["Runtime"]                 = tbl["Measured(wallclock) runtime"]
    tbl["sys+usr"]                 = tbl["USER"] * 1e6 + tbl["SYSTEM"] * 1e6
    tbl["Runtime w/o Evictions"]   = tbl["Runtime"] - tbl["Eviction Time"]/1e6

    degr = lambda exp, baseline, c: tbl.loc[tbl["EXP"] == exp, c] / baseline

    for exp in tbl["EXP"].unique():
        baseline = per_exp_baseline(exp, "Runtime")
        tbl.loc[tbl["EXP"] == exp, "Degradation(%)"] = degr(exp, baseline, "Runtime") * 100

        baseline = per_exp_baseline(exp, "Runtime w/o Evictions")
        tbl.loc[tbl["EXP"] == exp, "Degradation w/o Evictions(%)"] = degr(exp, baseline, "Runtime w/o Evictions") * 100

        tbl.loc[tbl["EXP"] == exp, "Baseline App Time(us)"] = per_exp_baseline(exp, "Measured(wallclock) runtime")

    if filter_raw:
        raw_cols = [c for c in tbl.columns.values if c.upper() == c]
        tbl.drop(columns=raw_cols, inplace=True)

    return tbl

def take_column_named(column_name, data):
    res = pd.DataFrame()

    for name,df in data.items():

        ## TODO::::: VERY VERY HACKY.. assumes all tables have data appropriately sorted
        ## sanity check later with more data, if these plots become crucial
        if "Experiment Name" not in res:
            res["Experiment Name"] = df["Experiment Name"]

        res["(%s)%s" % (name,column_name)] = df[column_name]
    return res

def get_nic_monitor_data(EXPERIMENT_TYPES, workload, experiment_dir):
    all_data = pd.DataFrame()
    for exp in EXPERIMENT_TYPES:
        tbl = pd.DataFrame()
        for f in os.listdir("%s/%s/%s/" % (experiment_dir, workload, exp)):
            if f.startswith("nic_monitor"):
                ratio = 0#int(f.split(".")[1])
                tmp = pd.read_csv("%s/%s/%s/%s" % (experiment_dir, workload, exp, f))
                tmp["RATIO"] = ratio
                tmp["Experiment Name"] = exp
                tbl = tbl.append(tmp)
        all_data = all_data.append(tbl)

        all_data["Time(s)"] = all_data["TIME"] / 1000
        all_data["Xmit(MB)"] = all_data["XMIT"] / (1024 * 1024)
        all_data["Recv(MB)"] = all_data["RECV"] / (1024 * 1024)

    return all_data.sort_values(["RATIO", "TIME"])
