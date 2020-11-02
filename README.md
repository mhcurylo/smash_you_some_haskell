 SMASH YOU SOME HASKELL ON A MINIKUBE


Before you begin, you need:


- Docker. For containers. https://docs.docker.com/engine/install/

- Minikube. For running a Kube cluster on your PC. https://minikube.sigs.k8s.io/docs/start/

- apib. apib is a cheap and cheerful command-line tool for performance testing. https://github.com/apigee/apib


Once you get all run



`./reset-minikube.sh`



It will destroy your old minikube, so be aware!


Then:


`./deploy.sh deployment/haskell-or-node-deployment`


And one of


`./smash.sh nodejs`

`./smash.sh haskell`

`./load.sh nodejs`

`./load.sh haskell`


In the repo, you might find the code to the services, as well as some bonuses, some of them need `perf` installed.

The minirepo is from https://github.com/lunaris/minirepo. It needs a lot.

