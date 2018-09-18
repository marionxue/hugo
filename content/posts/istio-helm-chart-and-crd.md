---
title: "Istio CRD 汇总与 Helm Chart 配置解析"
subtitle: "两个神奇的表格"
date: 2018-09-18T19:11:16+08:00
draft: false
categories: "service mesh"
tags: ["istio", "service mesh"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->

### Istio 中包含的 `CRD`(总共 `50` 个) 及其分类和用途

<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;border-color:#aabcfe;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#aabcfe;color:#669;background-color:#e8edff;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#aabcfe;color:#039;background-color:#b9c9fe;}
.tg .tg-baqh{text-align:center;vertical-align:top}
.tg .tg-0lax{text-align:left;vertical-align:top}
</style>
<table class="tg" style="undefined;table-layout: fixed; width: 1003px">
<colgroup>
<col style="width: 67px">
<col style="width: 227px">
<col style="width: 367px">
<col style="width: 279px">
<col style="width: 63px">
</colgroup>
  <tr>
    <th class="tg-baqh">﻿序号</th>
    <th class="tg-0lax">名称</th>
    <th class="tg-0lax">用途</th>
    <th class="tg-0lax">分类</th>
    <th class="tg-0lax">归属</th>
  </tr>
  <tr>
    <td class="tg-baqh">1</td>
    <td class="tg-0lax">virtualservices.networking.istio.io</td>
    <td class="tg-0lax">用于路由，定义virtual service</td>
    <td class="tg-0lax">networking</td>
    <td class="tg-0lax">pilot</td>
  </tr>
  <tr>
    <td class="tg-baqh">2</td>
    <td class="tg-0lax">destinationrules.networking.istio.io</td>
    <td class="tg-0lax">用于路由，定义destination rule</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">3</td>
    <td class="tg-0lax">serviceentries.networking.istio.io</td>
    <td class="tg-0lax">用于路由，定义service entry</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">4</td>
    <td class="tg-0lax">gateways.networking.istio.io</td>
    <td class="tg-0lax">用于路由，定义gateway</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">5</td>
    <td class="tg-0lax">envoyfilters.networking.istio.io</td>
    <td class="tg-0lax">使用filter为特定envoy添加特定配置</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">6</td>
    <td class="tg-0lax">policies.authentication.istio.io</td>
    <td class="tg-0lax">用于authn，作用域为namespace</td>
    <td class="tg-0lax">authentication</td>
    <td class="tg-0lax">citadel</td>
  </tr>
  <tr>
    <td class="tg-baqh">7</td>
    <td class="tg-0lax">meshpolicies.authentication.istio.io</td>
    <td class="tg-0lax">用于authn，作用域为global</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">8</td>
    <td class="tg-0lax">httpapispecbindings.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">apim</td>
    <td class="tg-0lax">mixer</td>
  </tr>
  <tr>
    <td class="tg-baqh">9</td>
    <td class="tg-0lax">httpapispecs.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">10</td>
    <td class="tg-0lax">quotaspecbindings.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">11</td>
    <td class="tg-0lax">quotaspecs.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">12</td>
    <td class="tg-0lax">rules.config.istio.io</td>
    <td class="tg-0lax">mixer rule，用于绑定handler和instance</td>
    <td class="tg-0lax">mixer core</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">13</td>
    <td class="tg-0lax">attributemanifests.config.istio.io</td>
    <td class="tg-0lax">定义envoy传递给mixer的用于policy和telemetry的attribute</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">14</td>
    <td class="tg-0lax">bypasses.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">mixer adapter用于处理从envoy收集的数据</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">15</td>
    <td class="tg-0lax">circonuses.config.istio.io</td>
    <td class="tg-0lax">定义circonus adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">16</td>
    <td class="tg-0lax">deniers.config.istio.io</td>
    <td class="tg-0lax">定义dinier adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">17</td>
    <td class="tg-0lax">fluentds.config.istio.io</td>
    <td class="tg-0lax">定义fluentd adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">18</td>
    <td class="tg-0lax">kubernetesenvs.config.istio.io</td>
    <td class="tg-0lax">定义kubernetesenv adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">19</td>
    <td class="tg-0lax">listcheckers.config.istio.io</td>
    <td class="tg-0lax">定义list adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">20</td>
    <td class="tg-0lax">memquotas.config.istio.io</td>
    <td class="tg-0lax">定义memquota adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">21</td>
    <td class="tg-0lax">noops.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">22</td>
    <td class="tg-0lax">opas.config.istio.io</td>
    <td class="tg-0lax">定义opa adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">23</td>
    <td class="tg-0lax">prometheuses.config.istio.io</td>
    <td class="tg-0lax">定义prometheus adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">24</td>
    <td class="tg-0lax">rbacs.config.istio.io</td>
    <td class="tg-0lax">定义rbac adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">25</td>
    <td class="tg-0lax">redisquotas.config.istio.io</td>
    <td class="tg-0lax">定义redisquota adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">26</td>
    <td class="tg-0lax">servicecontrols.config.istio.io</td>
    <td class="tg-0lax">定义servicecontrol adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">27</td>
    <td class="tg-0lax">signalfxs.config.istio.io</td>
    <td class="tg-0lax">定义signalfx adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">28</td>
    <td class="tg-0lax">solarwindses.config.istio.io</td>
    <td class="tg-0lax">定义solarwinds adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">29</td>
    <td class="tg-0lax">stackdrivers.config.istio.io</td>
    <td class="tg-0lax">定义stackdriver adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">30</td>
    <td class="tg-0lax">statsds.config.istio.io</td>
    <td class="tg-0lax">定义statsd adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">31</td>
    <td class="tg-0lax">stdios.config.istio.io</td>
    <td class="tg-0lax">定义stdio adapter</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">32</td>
    <td class="tg-0lax">apikeys.config.istio.io</td>
    <td class="tg-0lax">定义apikey template</td>
    <td class="tg-0lax">mixer instance用于定义从envoy收集的数据</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">33</td>
    <td class="tg-0lax">authorizations.config.istio.io</td>
    <td class="tg-0lax">定义authorization template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">34</td>
    <td class="tg-0lax">checknothings.config.istio.io</td>
    <td class="tg-0lax">定义checknothing template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">35</td>
    <td class="tg-0lax">kuberneteses.config.istio.io</td>
    <td class="tg-0lax">定义kubernetes template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">36</td>
    <td class="tg-0lax">listentries.config.istio.io</td>
    <td class="tg-0lax">定义listentry template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">37</td>
    <td class="tg-0lax">logentries.config.istio.io</td>
    <td class="tg-0lax">定义logentry template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">38</td>
    <td class="tg-0lax">edges.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">39</td>
    <td class="tg-0lax">metrics.config.istio.io</td>
    <td class="tg-0lax">定义metric template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">40</td>
    <td class="tg-0lax">quotas.config.istio.io</td>
    <td class="tg-0lax">定义quota template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">41</td>
    <td class="tg-0lax">reportnothings.config.istio.io</td>
    <td class="tg-0lax">定义reportnothing template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">42</td>
    <td class="tg-0lax">servicecontrolreports.config.istio.io</td>
    <td class="tg-0lax">定义servicecontrolreport template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">43</td>
    <td class="tg-0lax">tracespans.config.istio.io</td>
    <td class="tg-0lax">定义tracespan template</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">44</td>
    <td class="tg-0lax">rbacconfigs.rbac.istio.io</td>
    <td class="tg-0lax">用于authz，定义istio的rbac策略</td>
    <td class="tg-0lax">rbac</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">45</td>
    <td class="tg-0lax">serviceroles.rbac.istio.io</td>
    <td class="tg-0lax">用于authz，定义service role</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">46</td>
    <td class="tg-0lax">servicerolebindings.rbac.istio.io</td>
    <td class="tg-0lax">用于authz，定义service role binding</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">47</td>
    <td class="tg-0lax">adapters.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">others</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">48</td>
    <td class="tg-0lax">instances.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">49</td>
    <td class="tg-0lax">templates.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh">50</td>
    <td class="tg-0lax">handlers.config.istio.io</td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
  </tr>
</table>

### Istio Helm Chart 的安装配置解析

<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;border-color:#bbb;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#bbb;color:#594F4F;background-color:#E0FFEB;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#bbb;color:#493F3F;background-color:#9DE0AD;}
.tg .tg-baqh{text-align:center;vertical-align:top}
.tg .tg-0lax{text-align:left;vertical-align:top}
</style>
<table class="tg" style="undefined;table-layout: fixed; width: 1281px">
<colgroup>
<col style="width: 51px">
<col style="width: 161px">
<col style="width: 251px">
<col style="width: 214px">
<col style="width: 219px">
<col style="width: 385px">
</colgroup>
  <tr>
    <th class="tg-baqh">﻿序号</th>
    <th class="tg-0lax">chart</th>
    <th class="tg-0lax">文件</th>
    <th class="tg-0lax">k8s组件类型</th>
    <th class="tg-0lax">k8s组件名称</th>
    <th class="tg-0lax">用途</th>
  </tr>
  <tr>
    <td class="tg-baqh">1</td>
    <td class="tg-0lax">main</td>
    <td class="tg-0lax">_affinity.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义各个组件deployment chart中的nodeAffinity</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义各个组件chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">istio</td>
    <td class="tg-0lax">istio主配置configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">crds.yaml</td>
    <td class="tg-0lax">CustomResourceDefinition</td>
    <td class="tg-0lax">共50个</td>
    <td class="tg-0lax">istio需要的所有的crd资源</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">install-custom-resources.sh.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义grafana和security chart中configmap中所包含的脚本，验证istio-galley validatingwebhookconfiguration已经存在并且部署组件相关其他资源</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">sidecar-injector-configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">istio-sidecar-injector</td>
    <td class="tg-0lax">用于定义sidecar injector的configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh">2</td>
    <td class="tg-0lax">sidecarInjectorWebhook默认开启</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义sidecarInjectorWebhook chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-sidecar-injector-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义sidecarInjectorWebhook使用的clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-sidecar-injector-admin-role-binding-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义sidecarInjectorWebhook使用的clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-sidecar-injector</td>
    <td class="tg-0lax">用于定义sidecarInjectorWebhook使用的deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">mutatingwebhook.yaml</td>
    <td class="tg-0lax">MutatingWebhookConfiguration</td>
    <td class="tg-0lax">istio-sidecar-injector</td>
    <td class="tg-0lax">用于定义sidecarInjectorWebhook使用的mutatingwebhookconfiguration</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-sidecar-injector</td>
    <td class="tg-0lax">用于定义sidecarInjectorWebhook使用的service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-sidecar-injector-service-account</td>
    <td class="tg-0lax">用于定义sidecarInjectorWebhook使用的serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh">3</td>
    <td class="tg-0lax">security默认开启</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义security chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">cleanup-secrets.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-cleanup-secrets-service-account</td>
    <td class="tg-0lax">在helm删除istio后对citadel中的secret进行清理</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-cleanup-secrets-{{ .Release.Namespace }}</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-cleanup-secrets-{{ .Release.Namespace }}</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Job</td>
    <td class="tg-0lax">istio-cleanup-secrets</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-citadel-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义citadel相关clusterole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-citadel-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义citdel相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">istio-security-custom-resources</td>
    <td class="tg-0lax">用于定义citidel相关configmap，与global values中的mtls.enabled相关，是否启用全局的mtls authn</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">create-custom-resources-job.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-security-post-install-account</td>
    <td class="tg-0lax">在global values的mtls.enabled设置为true后才会生效，建立mtls相关serviceaccount，clusterrole，clusterrolebinding，以及comfigmap中定义的其他相关对象</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-security-post-install-{{ .Release.Namespace }}</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-security-post-install-role-binding-{{ .Release.Namespace }}</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Job</td>
    <td class="tg-0lax">istio-security-post-install</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-citadel</td>
    <td class="tg-0lax">用于定义citadel相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">enable-mesh-mtls.yaml</td>
    <td class="tg-0lax">MeshPolicy</td>
    <td class="tg-0lax">default</td>
    <td class="tg-0lax">在global values的mtls.enabled设置为true后，这些资源会写入configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">DestinationRule</td>
    <td class="tg-0lax">default</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">DestinationRule</td>
    <td class="tg-0lax">api-server</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">meshexpansion.yaml</td>
    <td class="tg-0lax">VirtualService</td>
    <td class="tg-0lax">meshexpansion-citadel</td>
    <td class="tg-0lax">在global values的meshExpansion设置为true后，新建citadel相关virtualservice</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">VirtualService</td>
    <td class="tg-0lax">meshexpansion-ilb-citadel</td>
    <td class="tg-0lax">在global values的meshExpansionILB设置为true后，新建citadel相关virtualservice</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-citadel</td>
    <td class="tg-0lax">用于定义citade相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-citadel-service-account</td>
    <td class="tg-0lax">用于定义citade相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh">4</td>
    <td class="tg-0lax">galley默认开启</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义galley chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-galley-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义galley相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-galley-admin-role-binding-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义galley相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">istio-galley-configuration</td>
    <td class="tg-0lax">用于定义galley相关configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-galley</td>
    <td class="tg-0lax">用于定义galley相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-galley</td>
    <td class="tg-0lax">用于定义galley相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-galley-service-account</td>
    <td class="tg-0lax">用于定义galley相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">validatingwehookconfiguration.yaml.tpl</td>
    <td class="tg-0lax">ValidatingWebhookConfiguration</td>
    <td class="tg-0lax">istio-galley</td>
    <td class="tg-0lax">用于定义对pilot和mixer的配置进行验证，与galley deployment关联</td>
  </tr>
  <tr>
    <td class="tg-baqh">5</td>
    <td class="tg-0lax">mixer默认开启</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义mixer chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">autoscale.yaml</td>
    <td class="tg-0lax">HorizontalPodAutoscaler</td>
    <td class="tg-0lax">istio-policy</td>
    <td class="tg-0lax">用于定义mixer，包括policy和telemetry的horizontalpodautoscaler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">HorizontalPodAutoscaler</td>
    <td class="tg-0lax">istio-telemetry</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-mixer-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义mixer相关clusterole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-mixer-admin-role-binding-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义mixer相关clusterolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">config.yaml</td>
    <td class="tg-0lax">attributemanifest</td>
    <td class="tg-0lax">istioproxy</td>
    <td class="tg-0lax">用于定义从envoy到mixer的attributemanifest</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">attributemanifest</td>
    <td class="tg-0lax">kubernetes</td>
    <td class="tg-0lax">用于定义从k8s到mixer的attributemanifest</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">stdio</td>
    <td class="tg-0lax">handler</td>
    <td class="tg-0lax">用于定义stdio handler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">logentry</td>
    <td class="tg-0lax">accesslog</td>
    <td class="tg-0lax">用于定义http logentry instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">logentry</td>
    <td class="tg-0lax">tcpaccesslog</td>
    <td class="tg-0lax">用于定义tcp logentry instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">rule</td>
    <td class="tg-0lax">stdio</td>
    <td class="tg-0lax">用于定义从accesslog.logentry到handler.stdio的rule，将accesslog发送至stdio</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">rule</td>
    <td class="tg-0lax">stdiotcp</td>
    <td class="tg-0lax">用于定义从tcpaccesslog.logentry到handler.stdio的rule，将tcpaccesslog发送至stdio</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">metric</td>
    <td class="tg-0lax">requestcount</td>
    <td class="tg-0lax">用于定义requestcount metric instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">metric</td>
    <td class="tg-0lax">requestduration</td>
    <td class="tg-0lax">用于定义requestduration metric instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">metric</td>
    <td class="tg-0lax">requestsize</td>
    <td class="tg-0lax">用于定义requestsize metric instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">metric</td>
    <td class="tg-0lax">responsesize</td>
    <td class="tg-0lax">用于定义responsesize metric instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">metric</td>
    <td class="tg-0lax">tcpbytesent</td>
    <td class="tg-0lax">用于定义tcpbytesent metric instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">metric</td>
    <td class="tg-0lax">tcpbytereceived</td>
    <td class="tg-0lax">用于定义tcpbytereceived metric instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">prometheus</td>
    <td class="tg-0lax">handler</td>
    <td class="tg-0lax">用于定义prometheus handler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">rule</td>
    <td class="tg-0lax">promhttp</td>
    <td class="tg-0lax">用于定义从requestcount.metric，requestduration.metric，requestsize.metric和responsesize.metric到handler.prometheus的rule，将http metric发送至prometheus</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">rule</td>
    <td class="tg-0lax">promtcp</td>
    <td class="tg-0lax">用于定义从tcpbytesent.metric和tcpbytereceived.metric到handler.prometheus的rule，将tcp metric发送至prometheus</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">kubernetesenv</td>
    <td class="tg-0lax">handler</td>
    <td class="tg-0lax">用于定义kubernetesenv handler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">rule</td>
    <td class="tg-0lax">kubeattrgenrulerule</td>
    <td class="tg-0lax">用于定义从attributes.kubernetes到handler.kubernetesenv的rule，生成kubernetes相关attribute</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">rule</td>
    <td class="tg-0lax">tcpkubeattrgenrulerule</td>
    <td class="tg-0lax">用于定义从attributes.kubernetes到handler.kubernetesenv的rule，生成kubernetes tcp相关attribute</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">kubernetes</td>
    <td class="tg-0lax">attributes</td>
    <td class="tg-0lax">用于定义kubernetes相关attribute instance</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">DestinationRule</td>
    <td class="tg-0lax">istio-policy</td>
    <td class="tg-0lax">用于定义istio-policy相关destinationrule</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">DestinationRule</td>
    <td class="tg-0lax">istio-telemetry</td>
    <td class="tg-0lax">用于定义istio-telemetry相关destinationrule</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">istio-statsd-prom-bridge</td>
    <td class="tg-0lax">用于定义istio-statsd-prom-bridge相关configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-policy</td>
    <td class="tg-0lax">用于定义istio-policy相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-telemetry</td>
    <td class="tg-0lax">用于定义istio-telemetry相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-policy</td>
    <td class="tg-0lax">用于定义istio-policy相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-telemetry</td>
    <td class="tg-0lax">用于定义istio-telemetry相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-mixer-service-account</td>
    <td class="tg-0lax">用于定义mixer相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">statsdtoprom.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-statsd-prom-bridge</td>
    <td class="tg-0lax">用于定义istio-statsd-prom-bridge相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-statsd-prom-bridge</td>
    <td class="tg-0lax">用于定义istio-statsd-prom-bridge相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh">6</td>
    <td class="tg-0lax">pilot默认开启</td>
    <td class="tg-0lax">autoscale.yaml</td>
    <td class="tg-0lax">horizontalPodAutoscaler</td>
    <td class="tg-0lax">istio-pilot</td>
    <td class="tg-0lax">用于定义pilot相关horizontalpodautoscaler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-pilot</td>
    <td class="tg-0lax">用于定义pilot相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-pilot</td>
    <td class="tg-0lax">用于定义pilot相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-pilot</td>
    <td class="tg-0lax">用于定义pilot相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">gateway.yaml</td>
    <td class="tg-0lax">Gateway</td>
    <td class="tg-0lax">istio-autogenerated-k8s-ingress</td>
    <td class="tg-0lax">用于定义pilot相关gateway，缺省向前兼容，使用ingress</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Gateway</td>
    <td class="tg-0lax">meshexpansion-gateway</td>
    <td class="tg-0lax">用于定义pilot相关gateway，如果global.meshExpansion设置为true，则将pilot暴露在gateway</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Gateway</td>
    <td class="tg-0lax">meshexpansion-ilb-gateway</td>
    <td class="tg-0lax">用于定义pilot相关gateway，如果global.meshExpansionILB设置为true，则将pilot暴露在internal gateway</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">meshexpansion.yaml</td>
    <td class="tg-0lax">VirtualService</td>
    <td class="tg-0lax">meshexpansion-pilot</td>
    <td class="tg-0lax">在global values的meshExpansion设置为true后，新建pilot相关virtualservice</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">VirtualService</td>
    <td class="tg-0lax">ilb-meshexpansion-pilot</td>
    <td class="tg-0lax">在global values的meshExpansionILB设置为true后，新建pilot相关virtualservice</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-pilot</td>
    <td class="tg-0lax">用于定义pilot相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-pilot-service-account</td>
    <td class="tg-0lax">用于定义pilot相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh">7</td>
    <td class="tg-0lax">gateways默认开启</td>
    <td class="tg-0lax">autoscale.yaml</td>
    <td class="tg-0lax">horizontalPodAutoscaler</td>
    <td class="tg-0lax">istio-ingressgateway</td>
    <td class="tg-0lax">用于定义ingressgateway相关horizontalpodautoscaler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">horizontalPodAutoscaler</td>
    <td class="tg-0lax">istio-egressgateway</td>
    <td class="tg-0lax">用于定义egressgateway相关horizontalpodautoscaler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">horizontalPodAutoscaler</td>
    <td class="tg-0lax">istio-ilbgateway</td>
    <td class="tg-0lax">用于定义ilbgateway相关horizontalpodautoscaler，默认关闭，只支持gcp</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-ingressgateway-{{ $.Release.Namespace }}</td>
    <td class="tg-0lax">用于定义ingressgateway相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-egressgateway-{{ $.Release.Namespace }}</td>
    <td class="tg-0lax">用于定义egressgateway相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-ilbgateway-{{ $.Release.Namespace }}</td>
    <td class="tg-0lax">用于定义ilbgateway相关clusterrole，默认关闭，只支持gcp</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-ingressgateway-{{ $.Release.Namespace }}</td>
    <td class="tg-0lax">用于定义ingressgateway相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-egressgateway-{{ $.Release.Namespace }}</td>
    <td class="tg-0lax">用于定义egressgateway相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-ilbgateway-{{ $.Release.Namespace }}</td>
    <td class="tg-0lax">用于定义ilbgateway相关clusterrolebindig，默认关闭，只支持gcp</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-ingressgateway</td>
    <td class="tg-0lax">用于定义ingressgateway相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-egressgateway</td>
    <td class="tg-0lax">用于定义egressgateway相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-ilbgateway</td>
    <td class="tg-0lax">用于定义ilbgateway相关deployment，默认关闭，只支持gcp</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-ingressgateway</td>
    <td class="tg-0lax">用于定义ingressgateway相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-egressgateway</td>
    <td class="tg-0lax">用于定义egressgateway相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-ilbgateway</td>
    <td class="tg-0lax">用于定义ilbgateway相关service，默认关闭，只支持gcp</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-ingressgateway-service-account</td>
    <td class="tg-0lax">用于定义ingressgateway相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-egressgateway-service-account</td>
    <td class="tg-0lax">用于定义egressgateway相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-ilbgateway-service-account</td>
    <td class="tg-0lax">用于定义ilbgateway相关serviceaccount，默认关闭，只支持gcp</td>
  </tr>
  <tr>
    <td class="tg-baqh">8</td>
    <td class="tg-0lax">prometheus默认开启</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义prometheus chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">prometheus-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义prometheus相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">prometheus-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义prometheus相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">prometheus</td>
    <td class="tg-0lax">用于定义prometheus相关configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">prometheus</td>
    <td class="tg-0lax">用于定义prometheus相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">prometheus</td>
    <td class="tg-0lax">用于定义prometheus相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">prometheus</td>
    <td class="tg-0lax">用于定义prometheus相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh">9</td>
    <td class="tg-0lax">telemetry-gateway默认关闭</td>
    <td class="tg-0lax">gateway.yaml</td>
    <td class="tg-0lax">Gateway</td>
    <td class="tg-0lax">istio-telemetry-gateway</td>
    <td class="tg-0lax">用于定义prometheus和grafana的gateway，如果prometheusEnabled设置为true，则添加prometheus相关gateway配置，如果grafanaEnabled设置为true，则添加grafana相关gateway配置</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">DestinationRule</td>
    <td class="tg-0lax">grafana</td>
    <td class="tg-0lax">定义prometheus相关destinationrule</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">DestinationRule</td>
    <td class="tg-0lax">prometheus</td>
    <td class="tg-0lax">定义grafana相关destinationrule</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">VirtualService</td>
    <td class="tg-0lax">telemetry-virtual-service</td>
    <td class="tg-0lax">用于定义prometheus和grafana的virtualservice，如果prometheusEnabled设置为true，则添加prometheus相关virtualservice配置，如果grafanaEnabled设置为true，则添加grafana相关virtualservice配置</td>
  </tr>
  <tr>
    <td class="tg-baqh">10</td>
    <td class="tg-0lax">ingress默认关闭legacy ingress support</td>
    <td class="tg-0lax">autoscale.yaml</td>
    <td class="tg-0lax">HorizontalPodAutoscaler</td>
    <td class="tg-0lax">istio-ingress</td>
    <td class="tg-0lax">用于定义ingress相关horizontalpodautoscaler</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-ingress-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义ingress相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-ingress-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义ingress相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-ingress</td>
    <td class="tg-0lax">用于定义ingress相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">istio-ingress</td>
    <td class="tg-0lax">用于定义ingress相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-ingress-service-account</td>
    <td class="tg-0lax">用于定义ingress相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh">11</td>
    <td class="tg-0lax">grafana默认关闭</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义grafana chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">istio-grafana-custom-resources</td>
    <td class="tg-0lax">用于定义grafana相关configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">create-custom-resources-job.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">istio-grafana-post-install-account</td>
    <td class="tg-0lax">用于定义grafana post install相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">istio-grafana-post-install-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义grafana post install相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-grafana-post-install-role-binding-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义grafana post install相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Job</td>
    <td class="tg-0lax">istio-grafana-post-install</td>
    <td class="tg-0lax">用于定义grafana post install相关job</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">grafana</td>
    <td class="tg-0lax">用于定义grafana相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">grafana-ports-mtls.yaml</td>
    <td class="tg-0lax">Policy</td>
    <td class="tg-0lax">grafana-ports-mtls-disabled</td>
    <td class="tg-0lax">对grafana访问开启mtls</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">pvc.yaml</td>
    <td class="tg-0lax">PersistentVolumeClaim</td>
    <td class="tg-0lax">istio-grafana-pvc</td>
    <td class="tg-0lax">如果persist设置为true，则为grafana新建pvc和pv</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">secret.yaml</td>
    <td class="tg-0lax">Secret</td>
    <td class="tg-0lax">grafana</td>
    <td class="tg-0lax">如果security.enabled设置为true，则为grafana启用authn</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">grafana</td>
    <td class="tg-0lax">用于定义grafana相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh">12</td>
    <td class="tg-0lax">servicegraph默认关闭</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义servicegraph chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">servicegraph</td>
    <td class="tg-0lax">用于定义servicegraph相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ingress.yaml</td>
    <td class="tg-0lax">Ingress</td>
    <td class="tg-0lax">servicegraph</td>
    <td class="tg-0lax">用于定义servicegraph相关ingress</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">servicegraph</td>
    <td class="tg-0lax">用于定义servicegraph相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh">13</td>
    <td class="tg-0lax">tracing默认关闭</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义tracing chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">istio-tracing</td>
    <td class="tg-0lax">用于定义jaeger tracing相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ingress-jaeger.yaml</td>
    <td class="tg-0lax">Ingress</td>
    <td class="tg-0lax">jaeger-query</td>
    <td class="tg-0lax">用于定义jaeger tracing相关ingress</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ingress.yaml</td>
    <td class="tg-0lax">Ingress</td>
    <td class="tg-0lax">tracing</td>
    <td class="tg-0lax">用于定义zipkin tracing相关ingress</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service-jaeger.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">jaeger-query</td>
    <td class="tg-0lax">用于定义jaeger tracing query相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">jaeger-collector</td>
    <td class="tg-0lax">用于定义jaeger tracing collector相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">jaeger-agent</td>
    <td class="tg-0lax">用于定义jaeger tracing agent相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">zipkin</td>
    <td class="tg-0lax">用于定义zipkin tracing相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">tracing</td>
    <td class="tg-0lax">用于定义jaeger tracing相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh">14</td>
    <td class="tg-0lax">kiali默认关闭</td>
    <td class="tg-0lax">clusterrole.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">kiali</td>
    <td class="tg-0lax">用于定义kiali相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">clusterrolebinding.yaml</td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">istio-kiali-admin-role-binding-{{ .Release.Namespace }}</td>
    <td class="tg-0lax">用于定义kiali相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">configmap.yaml</td>
    <td class="tg-0lax">ConfigMap</td>
    <td class="tg-0lax">kiali</td>
    <td class="tg-0lax">用于定义kiali相关configmap</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">kiali</td>
    <td class="tg-0lax">用于定义kiali相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ingress.yaml</td>
    <td class="tg-0lax">Ingress</td>
    <td class="tg-0lax">kiali</td>
    <td class="tg-0lax">用于定义kiali相关ingress</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">secrets.yaml</td>
    <td class="tg-0lax">Secret</td>
    <td class="tg-0lax">kiali</td>
    <td class="tg-0lax">用于定义kiali相关secret</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">service.yaml</td>
    <td class="tg-0lax">Service</td>
    <td class="tg-0lax">kiali</td>
    <td class="tg-0lax">用于定义kiali相关service</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">serviceaccount.yaml</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">kiali-service-account</td>
    <td class="tg-0lax">用于定义kiali相关serviceaccount</td>
  </tr>
  <tr>
    <td class="tg-baqh">15</td>
    <td class="tg-0lax">certmanager默认关闭</td>
    <td class="tg-0lax">_helpers.tpl</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">无</td>
    <td class="tg-0lax">用于定义certmanager chart中一些变量的默认值</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">crds.yaml</td>
    <td class="tg-0lax">CustomResourceDefinition</td>
    <td class="tg-0lax">clusterissuers.certmanager.k8s.io</td>
    <td class="tg-0lax">用于定义certmanager相关crd</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">CustomResourceDefinition</td>
    <td class="tg-0lax">issuers.certmanager.k8s.io</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">CustomResourceDefinition</td>
    <td class="tg-0lax">certificates.certmanager.k8s.io</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">deployment.yaml</td>
    <td class="tg-0lax">Deployment</td>
    <td class="tg-0lax">certmanager</td>
    <td class="tg-0lax">用于定义certmanager相关deployment</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">issuer.yaml</td>
    <td class="tg-0lax">ClusterIssuer</td>
    <td class="tg-0lax">letsencrypt-staging</td>
    <td class="tg-0lax">用于定义certmanager相关clusterissuer</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterIssuer</td>
    <td class="tg-0lax">letsencrypt</td>
    <td class="tg-0lax"></td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">rbac.yaml</td>
    <td class="tg-0lax">ClusterRole</td>
    <td class="tg-0lax">certmanager</td>
    <td class="tg-0lax">用于定义certmanager相关clusterrole</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">ClusterRoleBinding</td>
    <td class="tg-0lax">certmanager</td>
    <td class="tg-0lax">用于定义certmanager相关clusterrolebinding</td>
  </tr>
  <tr>
    <td class="tg-baqh"></td>
    <td class="tg-0lax"></td>
    <td class="tg-0lax">certmanager</td>
    <td class="tg-0lax">ServiceAccount</td>
    <td class="tg-0lax">certmanager</td>
    <td class="tg-0lax">用于定义certmanager相关serviceaccount</td>
  </tr>
</table>
