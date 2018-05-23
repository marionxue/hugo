---
title: "走进 Descheduler"
subtitle: "通过 Descheduler 来实现更高级的调度策略"
date: 2018-05-23T10:23:29Z
draft: false
categories: "kubernetes"
tags: ["kubernetes"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->
`kube-scheduler` 是 Kubernetes 中负责调度的组件，它本身的调度功能已经很强大了。但由于 Kubernetes 集群非常活跃，它的状态会随时间而改变，由于各种原因，你可能需要将已经运行的 Pod 移动到其他节点：

+ 某些节点负载过高
+ 某些资源对象被添加了 [node 亲和性](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#node-affinity-beta-feature) 或 [pod （反）亲和性](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#inter-pod-affinity-and-anti-affinity-beta-feature)
+ 集群中加入了新节点

一旦 Pod 启动之后 `kube-scheduler` 便不会再尝试重新调度它。根据环境的不同，你可能会有很多需要手动调整 Pod 的分布，例如：如果集群中新加入了一个节点，那么已经运行的 Pod 并不会被分摊到这台节点上，这台节点可能只运行了少量的几个 Pod，这并不理想，对吧？

## <p id="h2">1. Descheduler 如何工作？</p>

----

[Descheduler]() 会检查 Pod 的状态，并根据自定义的策略将不满足要求的 Pod 从该节点上驱逐出去。Descheduler 并不是 `kube-scheduler` 的替代品，而是要依赖于它。该项目目前放在 Kubernetes 的孵化项目中，还没准备投入生产，但经过我实验发现它的运行效果很好，而且非常稳定。那么该如何安装呢？

## <p id="h2">2. 部署方法</p>

你可以通过 `Job` 或 `CronJob` 来运行 descheduler。我已经创建了一个镜像 `komljen/descheduler:v0.5.0-4-ga7ceb671`（包含在下面的 yaml 文件中），但由于这个项目的更新速度很快，你可以通过以下的命令创建你自己的镜像：

```bash
$ git clone https://github.com/kubernetes-incubator/descheduler
$ cd descheduler && make image
```

然后打好标签 push 到自己的镜像仓库中。

通过我创建的 chart 模板，你可以用 `Helm` 来部署 descheduler，该模板支持 RBAC 并且已经在 Kubernetes v1.9 上测试通过。

添加我的 helm 私有仓库，然后部署 descheduler：

```bash
$ helm repo add akomljen-charts \
  https://raw.githubusercontent.com/komljen/helm-charts/master/charts/
  
$ helm install --name ds \
  --namespace kube-system \
  akomljen-charts/descheduler
```

你也可以不使用 helm，通过手动部署。首先创建 serviceaccount 和 clusterrolebinding：

```bash
# Create a cluster role
$ cat << EOF| kubectl create -n kube-system -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: descheduler
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list", "delete"]
- apiGroups: [""]
  resources: ["pods/eviction"]
  verbs: ["create"]
EOF

# Create a service account
$ kubectl create sa descheduler -n kube-system

# Bind the cluster role to the service account
$ kubectl create clusterrolebinding descheduler \
    -n kube-system \
    --clusterrole=descheduler \
    --serviceaccount=kube-system:descheduler
```

然后通过 `configmap` 创建 descheduler 策略。目前只支持四种策略：

+ [RemoveDuplicates](https://github.com/kubernetes-incubator/descheduler#removeduplicates)
+ [LowNodeUtilization](https://github.com/kubernetes-incubator/descheduler#lownodeutilization)
+ [RemovePodsViolatingInterPodAntiAffinity](https://github.com/kubernetes-incubator/descheduler#removepodsviolatinginterpodantiaffinity)
+ [RemovePodsViolatingNodeAffinity](https://github.com/kubernetes-incubator/descheduler#removepodsviolatingnodeaffinity)

默认这四种策略全部开启，你可以根据需要关闭它们。下面在 `kube-suystem` 命名空间中创建一个 configmap：

```yaml
$ cat << EOF| kubectl create -n kube-system -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: descheduler
data:
  policy.yaml: |-  
    apiVersion: descheduler/v1alpha1
    kind: DeschedulerPolicy
    strategies:
      RemoveDuplicates:
         enabled: false
      LowNodeUtilization:
         enabled: true
         params:
           nodeResourceUtilizationThresholds:
             thresholds:
               cpu: 20
               memory: 20
               pods: 20
             targetThresholds:
               cpu: 50
               memory: 50
               pods: 50
      RemovePodsViolatingInterPodAntiAffinity:
        enabled: true
      RemovePodsViolatingNodeAffinity:
        enabled: true
        params:
          nodeAffinityType:
          - requiredDuringSchedulingIgnoredDuringExecution
EOF
```

在 `kube-system` 命名空间中创建一个 CronJob：

```yaml
$ cat << EOF| kubectl create -n kube-system -f -
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: descheduler
spec:
  schedule: "*/30 * * * *"
  jobTemplate:
    metadata:
      name: descheduler
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: "true"
    spec:
      template:
        spec:
          serviceAccountName: descheduler
          containers:
          - name: descheduler
            image: komljen/descheduler:v0.5.0-4-ga7ceb671
            volumeMounts:
            - mountPath: /policy-dir
              name: policy-volume
            command:
            - /bin/descheduler
            - --v=4
            - --max-pods-to-evict-per-node=10
            - --policy-config-file=/policy-dir/policy.yaml
          restartPolicy: "OnFailure"
          volumes:
          - name: policy-volume
            configMap:
              name: descheduler
EOF
```

```bash
$ kubectl get cronjobs -n kube-system

NAME             SCHEDULE       SUSPEND   ACTIVE    LAST SCHEDULE   AGE
descheduler      */30 * * * *   False     0         2m              32m
```

该 CroJob 每 30 分钟运行一次，当 CronJob 开始工作后，可以通过以下命令查看已经成功结束的 Pod：

```bash
$ kubectl get pods -n kube-system -a | grep Completed

descheduler-1525520700-297pq          0/1       Completed   0          1h
descheduler-1525521000-tz2ch          0/1       Completed   0          32m
descheduler-1525521300-mrw4t          0/1       Completed   0          2m
```

也可以查看这些 Pod 的日志，然后根据需要调整 descheduler 策略：

```bash
$ kubectl logs descheduler-1525521300-mrw4t -n kube-system

I0505 11:55:07.554195       1 reflector.go:202] Starting reflector *v1.Node (1h0m0s) from github.com/kubernetes-incubator/descheduler/pkg/descheduler/node/node.go:84
I0505 11:55:07.554255       1 reflector.go:240] Listing and watching *v1.Node from github.com/kubernetes-incubator/descheduler/pkg/descheduler/node/node.go:84
I0505 11:55:07.767903       1 lownodeutilization.go:147] Node "ip-10-4-63-172.eu-west-1.compute.internal" is appropriately utilized with usage: api.ResourceThresholds{"cpu":41.5, "memory":1.3635487207675927, "pods":8.181818181818182}
I0505 11:55:07.767942       1 lownodeutilization.go:149] allPods:9, nonRemovablePods:9, bePods:0, bPods:0, gPods:0
I0505 11:55:07.768141       1 lownodeutilization.go:144] Node "ip-10-4-36-223.eu-west-1.compute.internal" is over utilized with usage: api.ResourceThresholds{"cpu":48.75, "memory":61.05259502942694, "pods":30}
I0505 11:55:07.768156       1 lownodeutilization.go:149] allPods:33, nonRemovablePods:12, bePods:1, bPods:19, gPods:1
I0505 11:55:07.768376       1 lownodeutilization.go:144] Node "ip-10-4-41-14.eu-west-1.compute.internal" is over utilized with usage: api.ResourceThresholds{"cpu":39.125, "memory":98.19259268881142, "pods":33.63636363636363}
I0505 11:55:07.768390       1 lownodeutilization.go:149] allPods:37, nonRemovablePods:8, bePods:0, bPods:29, gPods:0
I0505 11:55:07.768538       1 lownodeutilization.go:147] Node "ip-10-4-34-29.eu-west-1.compute.internal" is appropriately utilized with usage: api.ResourceThresholds{"memory":43.19826999287199, "pods":30.90909090909091, "cpu":35.25}
I0505 11:55:07.768552       1 lownodeutilization.go:149] allPods:34, nonRemovablePods:11, bePods:8, bPods:15, gPods:0
I0505 11:55:07.768556       1 lownodeutilization.go:65] Criteria for a node under utilization: CPU: 20, Mem: 20, Pods: 20
I0505 11:55:07.768571       1 lownodeutilization.go:69] No node is underutilized, nothing to do here, you might tune your thersholds further
I0505 11:55:07.768576       1 pod_antiaffinity.go:45] Processing node: "ip-10-4-63-172.eu-west-1.compute.internal"
I0505 11:55:07.779313       1 pod_antiaffinity.go:45] Processing node: "ip-10-4-36-223.eu-west-1.compute.internal"
I0505 11:55:07.796766       1 pod_antiaffinity.go:45] Processing node: "ip-10-4-41-14.eu-west-1.compute.internal"
I0505 11:55:07.813303       1 pod_antiaffinity.go:45] Processing node: "ip-10-4-34-29.eu-west-1.compute.internal"
I0505 11:55:07.829109       1 node_affinity.go:40] Executing for nodeAffinityType: requiredDuringSchedulingIgnoredDuringExecution
I0505 11:55:07.829133       1 node_affinity.go:45] Processing node: "ip-10-4-63-172.eu-west-1.compute.internal"
I0505 11:55:07.840416       1 node_affinity.go:45] Processing node: "ip-10-4-36-223.eu-west-1.compute.internal"
I0505 11:55:07.856735       1 node_affinity.go:45] Processing node: "ip-10-4-41-14.eu-west-1.compute.internal"
I0505 11:55:07.945566       1 request.go:480] Throttling request took 88.738917ms, request: GET:https://100.64.0.1:443/api/v1/pods?fieldSelector=spec.nodeName%3Dip-10-4-41-14.eu-west-1.compute.internal%2Cstatus.phase%21%3DFailed%2Cstatus.phase%21%3DSucceeded
I0505 11:55:07.972702       1 node_affinity.go:45] Processing node: "ip-10-4-34-29.eu-west-1.compute.internal"
I0505 11:55:08.145559       1 request.go:480] Throttling request took 172.751657ms, request: GET:https://100.64.0.1:443/api/v1/pods?fieldSelector=spec.nodeName%3Dip-10-4-34-29.eu-west-1.compute.internal%2Cstatus.phase%21%3DFailed%2Cstatus.phase%21%3DSucceeded
I0505 11:55:08.160964       1 node_affinity.go:72] Evicted 0 pods
```

哇哦，现在你的集群中已经运行了一个 descheduler！

## <p id="h2">3. 总结</p>

Kubernetes 的默认调度器已经做的很好，但由于集群处于不断变化的状态中，某些 Pod 可能运行在错误的节点上，或者你想要均衡集群资源的分配，这时候就需要 descheduler 来帮助你将某些节点上的 Pod 驱逐到正确的节点上去。我很期待正式版的发布！

## <p id="h2">4. 原文链接</p>

+ [Meet a Kubernetes Descheduler](https://akomljen.com/meet-a-kubernetes-descheduler/)


<style>
#h2{
    margin-bottom:2em;
    margin-right: 5px;
    padding: 8px 15px;
    letter-spacing: 2px;
    background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181));
    background-color: rgb(63, 81, 181);
    color: rgb(255, 255, 255);
    border-left: 10px solid rgb(51, 51, 51);
    border-radius:5px;
    text-shadow: rgb(102, 102, 102) 1px 1px 1px;
    box-shadow: rgb(102, 102, 102) 1px 1px 2px;
}
#note {
    font-size: 1.5rem;
    font-style: italic;
    padding: 0 1rem;
    margin: 2.5rem 0;
    position: relative;
    background-color: #fafeff;
    border-top: 1px dotted #9954bb;
    border-bottom: 1px dotted #9954bb;
}
#note-title {
    padding: 0.2rem 0.5rem;
    background: #9954bb;
    color: #FFF;
    position: absolute;
    left: 0;
    top: 0.25rem;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    border-radius: 4px;
    -webkit-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    -moz-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    -ms-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    -o-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    transform: rotate(-5deg) translateX(-10px) translateY(-25px);
}
#inline-yellow {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #f0ad4e;
}
#inline-green {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #5cb85c;
}
#inline-blue {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #2780e3;
}
#inline-purple {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #9954bb;
}
#div-border-left-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #df3e3e;
}
#div-border-left-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #f0ad4e;
}
#div-border-left-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #5cb85c;
}
#div-border-left-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #2780e3;
}
#div-border-left-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #9954bb;
}
#div-border-right-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #df3e3e;
}
#div-border-right-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #f0ad4e;
}
#div-border-right-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #5cb85c;
}
#div-border-right-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #2780e3;
}
#div-border-right-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #9954bb;
}
#div-border-top-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #df3e3e;
}
#div-border-top-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #f0ad4e;
}
#div-border-top-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #5cb85c;
}
#div-border-top-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #2780e3;
}
#div-border-top-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #9954bb;
}
</style>