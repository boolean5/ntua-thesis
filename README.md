# ntua-thesis
## Diploma Thesis: Optimizing Write Performance in the etcd Distributed Key-Value Store via Integration of the RocksDB Storage Engine
#### National Technical University of Athens, School of Electrical and Computer Engineering

#### Abstract

*Etcd* is an open-source, distributed key-value store with a focus on reliability. It was primarily designed to store metadata and is often used for service discovery, shared configuration and distributed locking. However, its numerous good qualities, such as its high-availability, simplicity and notable performance, in conjunction with the fact that it is an actively maintained project backed by a large developer community, render it an attractive option for other usecases as well. 

Etcd currently uses *BoltDB*, a read-optimized persistence solution based on *B+ trees*, as its storage engine. In the era of distributed computing, there is a wide range of write-intensive applications that would benefit from having a reliable way to store data across a cluster of machines. Examples of such applications include cloud backup services, sensor data collection, mail servers and social media websites. To that end, in this thesis we design and implement the replacement of BoltDB with *RocksDB*, a high-performance embedded database that internally uses a log-structured merge-tree (*LSM-tree*), in order to optimize etcd for write-heavy workloads. 

We achieve this by developing a Go wrapper that maps BoltDB API functions and concepts to their RocksDB counterparts, modifying core etcd code only where necessary. During this process, we make software contributions to some of the projects involved, implementing features that we needed but were missing. Furthermore, we verify the functionality and robustness of our implementation, using the functional test suite of etcd, among other tools. In addition, we set up a cluster of virtual machines on a cloud platform, in order to evaluate the performance of etcd with RocksDB as its storage engine using the built-in benchmark tool, and compare it to that of BoltDB-backed etcd. Then, we gradually apply a number of optimizations upon our initial implementation, examine the impact of a set of parameters on the results, and comment on the trade-offs of both approaches. Finally, we suggest some improvements and outline directions for further investigation on this topic.

**Note:** [thesis.pdf](https://github.com/boolean5/ntua-thesis/blob/master/thesis.pdf) begins with an extended summary of the thesis in Greek. The full text in English starts at page 59.
