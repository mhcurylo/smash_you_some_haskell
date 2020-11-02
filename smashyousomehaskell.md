---

title: Smash you some Haskell

author: Mateusz Curylo

...

# Smash you some Haskell on a Minikube.

Performance for Haskell microservices on Kubernetes.

---

# Who am I and what do I want to say


I am a Haskell Engineer at Habito.

We deploy our Dockerized Haskell Microservices to a Kubernetes cluster.


I will show and tell how to run rudimentary performance tests for your Haskell Kubernetes.


At the end I want you to understand that:

- the topography of your machine has significant influence on the performance of your deployment

- running even a `sketchy` performance tests can teach you a lot

- setting up requests and limits on Kubernetes deployments is a must

&nbsp; and it goes together with runtime settings

- both the threaded and non-threaded GHC runtime have their boons

- pinning down GHC process to an isolated processor is very nice



---



# The plan



1. Empiricism vs Rationalism in reasoning about performance.


2. Haskell microservice vs a Node.js microservice on a Minikube.


3. Haskell, Kubernetes and Docker performance tests.


4. Fold it up.



---



# The Great Feud in Ancient Greece



  `Rationalism vs Empiricism`


  `Empiricism` - Heraklit - the only constant changes.


  `Rationality` - Parmenides - change is an illusion as the subject of knowledge must be eternal.


  Platon, the ultimate source of modern rationality:


  "We have to assume that the world is a rational place as else we know nothing."


---


# Reasoning about performance



  Rationalism ------------------------------------------------------------------------------ Empiricism

  O notation - counting ops - micro benchmarking - tinkering - e2e perf testing - production monitoring



  Performance is a Rational domain if the world preserves ordering moving left to right.


  If performance is a Rational domain, then you can be reasonable about performance - if you use a good compiler and performant libraries, you do not have to measure your system.


"The real problem is that programmers have spent far too much time worrying about efficiency in the wrong places and at the wrong times; premature optimization is the root of all evil (or at least most of it) in programming."


---




# Is performance a Rational domain?





---




# Is performance a Rational domain?



  Nope. Software performance went postmodern on us.



  O notatation /= operation count /= microbenchmark



  It is a well-known fact in algorithm design (cache-oblivious algorithms, algorithm locality, introspective sorts, etc.) and has been talked about in the dev community.



Data-Oriented Design (Game Programming / C++)


  https://www.dataorienteddesign.com/dodbook/


  Mike Acton speech https://www.youtube.com/watch?v=rX0ItVEVjHc



Mechanical Sympathy (Java / LMAX Disruptor)


  https://mechanical-sympathy.blogspot.com/




---




# History of computing as physical token manipulation


- The Oxen, 13.000 BC, 2 meters long (10^1)


- Tokens representing Oxen, 8.000 BC, 1-3cm (10^-2)


- α, aleph, oxhead in the early alphabet, 1500 BC (10^-3)


- IBM 350 Hard Drive, 1956, 12mm2 per word (10^-3)


- Intel 4004, 1971 AD, 10 µm (10^-5)


- Ryzen 5600, 2020 AD, 7 nm (10^-9)



  "Modern writing spans nine orders of magnitude."


  (or fourteen counting the length of submarine cables)



---


# How does it work in practice?


Hardware has a topology.


- operation ~3 per cycle (0.1 ns) (10^-10) - aleph (10^-3)


- L1D Cache 4-8 cycles (0.5 ns) (10^-10) - still writing


- L2 Cache 12 cycles (1.2 ns) (10^-9) - token (10^-2)


- L3 40 cycles (4 ns) (10^-9) - still token


- DDRAM 100ns (~1000 cycles) (10^-7) - an Ox (10^0)


- full context switch 1µm (10^-6) - a room (10^1)


- NVMe 20µm (10^-5) - a building (10^2)



There are three orders of magnitude between L1 and DDRAM, which is an Ox vs an aleph.


It is like writing letters vs moving furniture.


Throughput of on thousand requests per second vs ten requests per seconds.


One hundred frames per second vs one frame per second.




---




# How bad does it get?



Lets stress test a Node.js server vs a servant Haskell set up as in `stack new` template.



`apib -c 200 -d 20 -W 25 'http://192.168.49.2:30009/item'`



---




# Why?



There are many culprits: Kubernetes, Docker, Hardware topology, Haskell runtime settings.


Worst offenders are GHC runtime settings - a threaded GHC runtime with -N setting.


Load balancing green threads on GHC capabilities by GHC runtime is fighting with load balancing Linux process by Completly Fair Scheduler.


Green thread switch (L1 cache) vs full context switch!


"A perfect storm is spanning four orders of magnitude."




---




# Curing the wounds



- Set your requests and limits in Kubernetes.


- Match them with your runtime thread settings.


- Let's check non-threaded runtime for N2



---




# Is it a fair comparison vs node?



- Node.js at two replicas


- threaded -N1 runtime at two replicas


- non-threaded runtime at two replicas



---



# Lets go wild



- kernel level isolation of CPU


- run docker with` --cpuset-cpus`



"You can set up your Kubernetes with static CPU-manager!"



---



# A fold!



Set up your GHC runtime together with your Kubernetes limits and requests.


Context switches in Haskell runtime are costly; you might consider a non-threaded runtime.


Non-threaded runtime has two drawbacks - blocking FFI and limit of 1000 connections.



The world does not care about your arguments—test stuff.



---

# A Table!

| Deployment       | Throughput   |
| ---------------- | ----------- |
| Node.js          |             |
| -N               |             |
| -N2              |             |
| Node.js      x 2 |             |
| -N1          x 2 |             |
| non-threaded x 2 |             |
| pinned N1        |             |
| pinned nt        |             |
| pinned node      |             |


---

# Questions


