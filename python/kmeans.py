from mem_pattern_trace import *
import os
os.environ["MKL_NUM_THREADS"] = "1"
os.environ["NUMEXPR_NUM_THREADS"] = "1"
os.environ["OMP_NUM_THREADS"] = "1"

import gc
gc.disable()

import resource
import numpy as np
#from sklearn.cluster import KMeans
#from sklearn.datasets.samples_generator import make_blobs
#from sklearn.datasets import make_blobs

syscall(mem_pattern_trace, TRACE_START | TRACE_AUTO)
from scipy.cluster.vq import kmeans
np.random.seed(42)

#samples, labels = make_blobs(n_samples=1500000, centers=10, random_state=0)
samples = np.random.rand(30000, 100)
#print (samples)
#k_means = KMeans(10, random_state=0)
#k_means.fit(samples)

kmeans(samples, 10, iter=20, seed=4)

#syscall(mem_pattern_trace, TRACE_END)

rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
print("Max RSS: %d kb or %d pages" % (rss, rss/4))
