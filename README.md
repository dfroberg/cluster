<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My Kubernetes Lab cluster :sailboat:

_... managed with Flux and Renovate_ :robot:

</div>

<br/>

<div align="center">


[![k3s](https://img.shields.io/badge/k3s-v1.22.3-brightgreen?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![renovate](https://img.shields.io/badge/renovate-enabled-brightgreen?style=for-the-badge&logo=renovatebot&logoColor=white)](https://github.com/renovatebot/renovate)
[![Lines of code](https://img.shields.io/tokei/lines/github/dfroberg/cluster?style=for-the-badge&color=brightgreen&label=lines&logo=codefactor&logoColor=white)](https://github.com/dfroberg/cluster/graphs/contributors)
  
</div>

<div align="center">

[![Lab-Healthchecks](https://healthchecks.k8s.aml.ink/badge/d462aef9-22af-48cb-b729-5ffc1947f2a5/LeDDBdvu-2.svg)](https://github.com/dfroberg/cluster/tree/main/cluster/core/monitoring/healthchecks)

</div>
---

## :book:&nbsp; Overview

This is home to my personal Kubernetes lab cluster. [Flux](https://github.com/fluxcd/flux2) watches this Git repository and makes the changes to my cluster based on the manifests in the [cluster](./cluster/) directory. [Renovate](https://github.com/renovatebot/renovate) also watches this Git repository and creates pull requests when it finds updates to Docker images, Helm charts, and other dependencies.

For more information, head on over to my [docs](https://dfroberg.github.io/cluster/).

## :handshake:&nbsp; Community

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community as well as [onedr0p](https://onedr0p.github.io/home-cluster/) which cluster setup has been a source of inspiration.
