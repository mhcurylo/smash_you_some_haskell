---
title: Smash you some Haskell

author: Mateusz Curylo

...

# Smash you some Haskell on a Minikube.

Performance for Haskell microservices on Kubernetes.

Repo:

<https://github.com/mhcurylo/smash_you_some_haskell>

## ./smash.sh


`apib -c 200 -d 20 -w 5 -W 25 'http://$SERVICE/item'`


TLDR:

| deployment          | throughput req/s |    mean   |  median  |      99th  |         max |   st. dev  |
| ------------------- | ---------------- | --------- | -------- | ---------- | ----------- | ---------- |
| haskell -N --cpus=1 |          77.477  |  2473.046 | 1867.393 |  20222.429 |   29520.868 |   2992.851 |
| haskell -N1 pinned  |        3429.445  |    33.273 |   32.529 |     53.987 |     102.566 |      4.007 |


---

# Hello


I am a Haskell Engineer at Habito.

We deploy our Haskell Microservices to a Kubernetes cluster.
If you want to see how to build nice Haskell Docker containers check:

<https://github.com/lunaris/minirepo>


I will show and tell rudimentary performance tests for Haskell on Kubernetes.

At the end I want you to understand that:

- hardware topology counts
- even a `sketchy` performance test helps
- setting up requests and limits on Kubernetes is a must
- threaded and non-threaded GHC runtime are both fine, `-N` is not
- pinning down GHC process to the processor is nice indeed


---


# The plan


1. Talk Empiricism and Rationalism in reasoning about performance.
2. Run Haskell microservice vs a Node.js microservice on a Minikube.
3. Talk Haskell runtime on Kubernetes.
4. Show and tell Haskell, Kubernetes and Docker performance tests.
5. Fold it up.


---


# Roots I - The Great Feud in Ancient Greece


  `Rationalism` vs `Empiricism`

  `Empiricism` - Heraklit - the only constant is change.

  `Rationalism` - Parmenides - change is an illusion, world as the object of knowledge is eternal.


  Platon, the ultimate source of modern rationalism:

  "If the world is not a rational domain, then we know nothing. Thus the world is rational."

  Rational domain - a domain which has one complete description.

---



# Is performance a Rational domain?

  Rationalism ------------------------------------------------------------------------------ Empiricism
  O notation - counting ops - micro benchmarking - tinkering - e2e perf testing - production monitoring


  Performance is a rational domain if the world preserves ordering moving left to the right,
  and this ordering is maintained on composition.

  If performance is a rational domain, then you can be reasonable about performance:
  if you use a good compiler and performant libraries, you do not have to measure your system.

  "premature optimization is the root of all evil (or at least most of it) in programming."

---



# Is performance a Rational domain? Preservation of Ordering over description level.


Sorting Vector Int8 - Insertion sort and Merge sort, 10000 runs.


| sort   | size   | O notation | ops count     | time   | ops/cycle |
| ------ | ------ | ---------- | ------------- | ------ | --------- |
| insert |  50    |      n 2   |   368,554,887 |  35.52 |   2.71    |
| merge  |  50    |  n log n   |   408,586,439 |  53.34 |   1.97    |
| insert |  100   |      n 2   | 1,142,296,574 |  77.27 |   3.88    |
| merge  |  100   |  n log n   |   897,500,028 | 114.99 |   2.05    |
| insert |  150   |      n 2   | 2,360,521,862 | 171.86 |   3.62    |
| merge  |  150   |  n log n   | 1,257,814,176 | 175.85 |   1.89    |
| insert |  200   |      n 2   | 4,037,779,266 | 283.34 |   3.75    |
| merge  |  200   |  n log n   | 1,944,364,708 | 281.74 |   1.82    |



Worst case for insertion sort - reverse sorted order.



---


# Is performance a Rational domain? Preservation of Ordering over composition.


Sorting Vector Int8 vs Vector Int64 - Insertion sort and Merge sort, Criterion.


| sort   | size   | type  | time      |
| ------ | ------ | ------| --------- |
| insert |  100   | Int8  | 8.641 μs  |
| merge  |  100   | Int8  | 10.36 μs  |
| insert |  100   | Int64 | 10.04 μs  |
| merge  |  100   | Int64 | 9.920 μs  |


Worst case for insertion sort - reverse sorted order.


---


# Is performance a Rational domain?


  Nope. Software performance went postmodern on us.

  Postmodern means there many different descriptions with different truth functions.

  O notatation /= operation count /= microbenchmark


  It is known in algorithm design
  (cache-oblivious algorithms, algorithm locality, introspective sorts, etc.).

  It has been talked about in the dev community.


Data-Oriented Design (Game Programming / C++)
  <https://www.dataorienteddesign.com/dodbook/>
  Mike Acton speech <https://www.youtube.com/watch?v=rX0ItVEVjHc>


Mechanical Sympathy (Java / LMAX Disruptor)
  <https://mechanical-sympathy.blogspot.com/>



---





# Roots II - History of computing as physical token manipulation


| thing            | size   |      year | scale  |
| ---------------- | -------| --------- | ------ |
| an ox            |    2 m |  13000 BC |   10^0 |
| token oxen       | 1-3 cm |   8000 BC |  10^-2 |
| α, aleph, oxhead | < 1 cm |   1500 BC |  10^-3 |
| IBM 350 HD word  | 3.4 mm |   1956 AD |  10^-3 |
| Intel 4004       |  10 µm |   1971 AD |  10^-5 |
| Ryzen 5600       |   7 nm |   2020 AD |  10^-9 |


"Modern writing spans nine orders of magnitude."

(or fourteen counting the length of submarine cables)

---

# How does it work in practice?

  Hardware has a topology.

  | event             | time in ns    | cycles  | scale  | compare        |
  | ----------------- | ------------- | ------- | ------ | -------------- |
  | operation         |       0.03 ns |    1/3  | 10^-11 | point (10^-4)  |
  | L1D Cache access  |        0.5 ns |    4-8  | 10^-10 | aleph (10^-3)  |
  | L2 Cache          |        1.2 ns |     12  | 10^-9  | token (10^-2)  |
  | L3 Cache          |          4 ns |     40  | 10^-9  | token (10^-2)  |
  | DDRAM             |        100 ns |   1000  | 10^-7  | an Ox (10^-0)  |
  | context switch    |       1000 ns |  10000  | 10^-6  | a small herd   |
  | NVMe              |      20000 ns | 200000  | 10^-5  | a larger herd  |


  There are three orders of magnitude between L1 and DDRAM, which is an Ox vs an aleph.

  It is like writing letters vs herding Oxen.

  Like 100 fps / 1 fps.


---



# How bad does it get?



  Lets stress test a Node.js server vs a servant Haskell set up as in `stack new` template.


---




# It gets terrible!


## ./smash.sh


`apib -c 200 -d 20 -w 5 -W 25 'http://192.168.49.2:30009/item'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| node vanilla        |        3002.946  |  41.562 |  41.819 |    64.938 |   85.344  |    10.088 |
| haskell vanilla -N  |         379.910  | 507.447 | 394.532 |  2188.318 | 7509.695  |   470.543 |



## ./load.sh


`apib -c 200 -d 25 -w 5 -W 100 'http://192.168.49.2:30002/item/1'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| node vanilla        |        1983.330  |   0.822 |   0.503 |     5.993 |    16.227 |     1.325 |
| haskell vanilla -N  |        1945.258  |   2.778 |   0.700 |    28.198 |    67.245 |     5.684 |



---



# Why?


There are many culprits: Kubernetes, Docker, Hardware topology, Haskell runtime settings.

Worst offenders are GHC runtime settings - a threaded GHC runtime with -N setting.

Load balancing green threads on GHC capabilities by GHC runtime is fighting with load balancing Linux process by Completly Fair Scheduler.

Worst case - a full context switch instead of a green thread switch (L1 cache).

| event             | time in ns    | cycles  | scale  | compare        |
| ----------------- | ------------- | ------- | ------ | -------------- |
| L1D Cache access  |        0.5 ns |    4-8  | 10^-10 | aleph (10^-3)  |
| context switch    |      10000 ns |  10000  | 10^-6  | a small herd   |


"A perfect storm spanning four orders of magnitude."


---



# Curing the wounds


1. Set requests and limits in Kubernetes.
2. Match them with the runtime thread settings.

Let's check threaded runtime with -N2 (2 capablities)


---


## ./smash.sh


`apib -c 200 -d 20 -w 5 -W 25 'http://192.168.49.2:30009/item'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| node vanilla        |        3002.946  |  41.562 |  41.819 |    64.938 |   85.344  |    10.088 |
| haskell vanilla -N  |         379.910  | 507.447 | 394.532 |  2188.318 | 7509.695  |   470.543 |
| haskell -N2         |        3181.440  |  37.821 |  37.077 |    64.794 |  116.703  |     9.111 |




## ./load.sh


`apib -c 200 -d 25 -w 5 -W 100 'http://192.168.49.2:30002/item/1'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| node vanilla        |        1983.330  |   0.822 |   0.503 |     5.993 |    16.227 |     1.325 |
| haskell vanilla -N  |        1945.258  |   2.778 |   0.700 |    28.198 |    67.245 |     5.684 |
| haskell -N2         |        1983.920  |   0.727 |   0.567 |     2.955 |     7.583 |     0.906 |



---


# Is it a fair comparison vs node?

- Node.js at two replicas?
- threaded -N1 runtime at two replicas?
- non-threaded runtime at two replicas?


---


# Lets get fair


## ./smash.sh


`apib -c 200 -d 20 -w 5 -W 25 'http://192.168.49.2:30009/item'`

| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| haskell -N2         |        3181.440  |  37.821 |  37.077 |    64.794 |  116.703  |     9.111 |
| node x 2            |        5754.874  |   9.721 |   8.773 |    23.813 |  38.057   |     4.158 |


## ./load.sh


`apib -c 200 -d 25 -w 5 -W 100 'http://192.168.49.2:30002/item/1'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| haskell -N2         |        1983.920  |   0.727 |   0.567 |     2.955 |     7.583 |     0.906 |
| node x 2            |        1985.433  |   0.661 |   0.568 |     2.665 |    10.879 |     0.798 |


---


# Lets fight back


## ./smash.sh


`apib -c 200 -d 20 -w 5 -W 25 'http://192.168.49.2:30009/item'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| haskell -N2         |        3181.440  |  37.821 |  37.077 |    64.794 |  116.703  |     9.111 |
| node x 2            |        5754.874  |   9.721 |   8.773 |    23.813 |   38.057  |     4.158 |
| haskell -N1 x 2     |        3511.815  |  31.912 |  31.190 |    56.862 |   56.862  |     7.858 |
| haskell nt* x 2     |        6100.491  |   7.755 |   7.124 |    38.159 |   80.610  |     5.376 |


 \* non-threaded



## ./load.sh


`apib -c 200 -d 25 -w 5 -W 100 'http://192.168.49.2:30002/item/1'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| haskell -N2         |        1983.920  |   0.727 |   0.567 |     2.955 |     7.583 |     0.906 |
| node x 2            |        1985.433  |   0.661 |   0.568 |     2.665 |    10.879 |     0.798 |
| haskell -N1 x 2     |        1983.918  |   0.712 |   0.555 |     3.041 |     9.991 |     0.906 |
| haskell nt*  x 2     |        1983.920  |   0.722 |   0.448 |     6.400 |    13.293 |     1.307 |


 \* non-threaded


---




# Lets go wild


- kernel level isolation of CPU
- run docker with` --cpuset-cpus`


"You can set up your Kubernetes with static CPU-manager!"


---


# Lets go wild (with --cpus=1)



## ./smash.sh


`apib -c 200 -d 20 -w 5 -W 25 'http://$SERVICE/item'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| node                |        2420.482  |  57.576 |  55.787 |   109.629 |  142.225  |    16.987 |
| node pinned         |        3054.482  |  40.420 |  40.357 |    68.553 |   91.950  |    10.396 |
| haskell -N1         |        1961.947  |  76.896 |  67.669 |   158.301 |  244.385  |    26.767 |
| haskell -N1 pinned  |        3429.445  |  33.273 |  32.529 |    53.987 |  102.566  |     4.007 |
| haskell nt*         |        2821.169  |  45.855 |  44.196 |   130.040 |  193.305  |    36.720 |
| haskell nt* pinned  |        3042.183  |  40.698 |  37.954 |   123.022 |  166.615  |    35.489 |


\* non-threaded


## ./load.sh


`apib -c 200 -d 25 -w 5 -W 100 'http://$SERVICE/item/1'`


| deployment          | throughput req/s |    mean |  median |      99th |       max |   st. dev |
| ------------------- | ---------------- | ------- | ------- | --------- | --------- | --------- |
| node                |        1893.539  |   5.594 |   4.072 |    31.057 |    48.096 |     5.506 |
| node pinned         |        1918.405  |   4.187 |   0.654 |    21.097 |    45.071 |     4.040 |
| haskell -N1         |        1945.317  |   4.543 |   4.543 |    14.708 |    21.980 |     3.064 |
| haskell -N1 pinned  |        1957.192  |   2.124 |   0.634 |     7.646 |    29.726 |     1.445 |
| haskell nt*         |        1899.890  |   5.258 |   2.056 |    49.594 |    73.156 |     9.047 |
| haskell nt* pinned  |        1946.967  |   2.724 |   1.627 |    20.787 |    55.740 |     3.747 |



\* non-threaded


---



# A fold!


- hardware topology counts
- even a `sketchy` performance test helps
- setting up requests and limits on Kubernetes is a must
- threaded and non-threaded GHC runtime are both fine, `-N` is not
- pinning down GHC process to the processor is nice indeed


more:

- set up your GHC runtime together with your Kubernetes limits and requests and do set them up
- context switches in Haskell runtime are costly; you might consider a non-threaded runtime
- non-threaded runtime has two drawbacks - blocking FFI and limit of 1000 connections

The world does not make any sense and does not care about your arguments — test stuff.

PS. make sure to turn on compiler optimizations


---


# Questions


## ./smash.sh


`apib -c 200 -d 20 -w 5 -W 25 'http://$SERVICE/item'`


| deployment          | throughput req/s |    mean   |  median  |      99th  |         max |   st. dev  |
| ------------------- | ---------------- | --------- | -------- | ---------- | ----------- | ---------- |
| haskell -N --cpus=1 |          77.477  |  2473.046 | 1867.393 |  20222.429 |   29520.868 |   2992.851 |
| haskell -N1 pinned  |        3429.445  |    33.273 |   32.529 |     53.987 |     102.566 |      4.007 |






