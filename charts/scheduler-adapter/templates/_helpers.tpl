{{- define "template.helmTemplateVersion" -}}
helm.sh/template: 1.0.1
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "application.name" -}}
{{- default .Chart.Name .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "application.fullname" -}}
{{- if .Values.fullname }}
{{- .Values.fullname | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "template.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "template.labels" -}}
helm.sh/chart: {{ include "template.chart" . }}
{{ include "template.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "template.selectorLabels" -}}
app.kubernetes.io/name: {{ include "application.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "application.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "application.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{- define "template.defaultEnv" -}}
env:
## from 'template.defaultEnv'
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
{{- end }}

{{- define "template.command" -}}
{{- if $.Values.command }}
command:
  {{- tpl (toYaml $.Values.command) $ | nindent 2 }}
{{- end }}
{{- end }}


{{- define "template.args" -}}
{{- if $.Values.args }}
args:
  {{- tpl (toYaml $.Values.args) $ | nindent 2 }}
{{- end }}
{{- end }}


{{- define "template.env" -}}
{{- if $.Values.env }}
## from '$.Values.env'
{{ tpl (toYaml $.Values.env) $ }}
{{- end }}
{{- end }}

{{- define "template.extraEnv" -}}
{{- if $.Values.extraEnv }}
{{- range $extraEnvName, $extraEnvValue := $.Values.extraEnv }}
## from '$.Values.extraEnv'
- name: {{ $extraEnvName }}
  value: {{ tpl $extraEnvValue $ | squote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "template.extraEnvVars" -}}
{{- if $.Values.extraEnvVars }}
{{- range $extraEnvVarsName, $extraEnvVarsValue := $.Values.extraEnvVars }}
## from '$.Values.extraEnvVars'
- name: {{ $extraEnvVarsName }}
  value: {{ tpl $extraEnvVarsValue $ | squote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "template.envFrom" -}}
{{- if $.Values.envFrom }}
envFrom:
  {{- tpl (toYaml $.Values.envFrom) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.startupProbe" -}}
{{- if $.Values.startupProbe }}
{{- if not (eq ($.Values.startupProbe.enabled | toString) "false") }}
startupProbe:
  {{- if $.Values.startupProbe.failureThreshold }}
  failureThreshold: {{ tpl ($.Values.startupProbe.failureThreshold | toString) $ }}
  {{- end }}
  {{- if $.Values.startupProbe.initialDelaySeconds }}
  initialDelaySeconds: {{ tpl ($.Values.startupProbe.initialDelaySeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.startupProbe.periodSeconds }}
  periodSeconds: {{ tpl ($.Values.startupProbe.periodSeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.startupProbe.successThreshold }}
  successThreshold: {{ tpl ($.Values.startupProbe.successThreshold | toString) $ }}
  {{- end }}
  {{- if $.Values.startupProbe.timeoutSeconds }}
  timeoutSeconds: {{ tpl ($.Values.startupProbe.timeoutSeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.startupProbe.httpGet }}
  httpGet: 
    {{- tpl (toYaml $.Values.startupProbe.httpGet) $ | nindent 4 }}
  {{- end }}
  {{- if $.Values.startupProbe.tcpSocket }}
  tcpSocket: 
    {{- tpl (toYaml $.Values.startupProbe.tcpSocket) $ | nindent 4 }}
  {{- end }}
  {{- if $.Values.startupProbe.exec }}
  exec: 
    {{- tpl (toYaml $.Values.startupProbe.exec) $ | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "template.livenessProbe" -}}
{{- if $.Values.livenessProbe }}
{{- if not (eq ($.Values.livenessProbe.enabled | toString) "false") }}
livenessProbe:
  {{- if $.Values.livenessProbe.failureThreshold }}
  failureThreshold: {{ tpl ($.Values.livenessProbe.failureThreshold | toString) $ }}
  {{- end }}
  {{- if $.Values.livenessProbe.initialDelaySeconds }}
  initialDelaySeconds: {{ tpl ($.Values.livenessProbe.initialDelaySeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.livenessProbe.periodSeconds }}
  periodSeconds: {{ tpl ($.Values.livenessProbe.periodSeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.livenessProbe.successThreshold }}
  successThreshold: {{ tpl ($.Values.livenessProbe.successThreshold | toString) $ }}
  {{- end }}
  {{- if $.Values.livenessProbe.timeoutSeconds }}
  timeoutSeconds: {{ tpl ($.Values.livenessProbe.timeoutSeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.livenessProbe.httpGet }}
  httpGet: 
    {{- tpl (toYaml $.Values.livenessProbe.httpGet) $ | nindent 4 }}
  {{- end }}
  {{- if $.Values.livenessProbe.tcpSocket }}
  tcpSocket: 
    {{- tpl (toYaml $.Values.livenessProbe.tcpSocket) $ | nindent 4 }}
  {{- end }}
  {{- if $.Values.livenessProbe.exec }}
  exec: 
    {{- tpl (toYaml $.Values.livenessProbe.exec) $ | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}



{{- define "template.readinessProbe" -}}
{{- if $.Values.readinessProbe }}
{{- if not (eq ($.Values.readinessProbe.enabled | toString) "false") }}
readinessProbe:
  {{- if $.Values.readinessProbe.failureThreshold }}
  failureThreshold: {{ tpl ($.Values.readinessProbe.failureThreshold | toString) $ }}
  {{- end }}
  {{- if $.Values.readinessProbe.initialDelaySeconds }}
  initialDelaySeconds: {{ tpl ($.Values.readinessProbe.initialDelaySeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.readinessProbe.periodSeconds }}
  periodSeconds: {{ tpl ($.Values.readinessProbe.periodSeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.readinessProbe.successThreshold }}
  successThreshold: {{ tpl ($.Values.readinessProbe.successThreshold | toString) $ }}
  {{- end }}
  {{- if $.Values.readinessProbe.timeoutSeconds }}
  timeoutSeconds: {{ tpl ($.Values.readinessProbe.timeoutSeconds | toString) $ }}
  {{- end }}
  {{- if $.Values.readinessProbe.httpGet }}
  httpGet: 
    {{- tpl (toYaml $.Values.readinessProbe.httpGet) $ | nindent 4 }}
  {{- end }}
  {{- if $.Values.readinessProbe.tcpSocket }}
  tcpSocket: 
    {{- tpl (toYaml $.Values.readinessProbe.tcpSocket) $ | nindent 4 }}
  {{- end }}
  {{- if $.Values.readinessProbe.exec }}
  exec: 
    {{- tpl (toYaml $.Values.readinessProbe.exec) $ | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "template.resources" -}}
{{- if $.Values.resources }}
resources:
  {{- tpl (toYaml $.Values.resources) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.securityContext" -}}
{{- if $.Values.securityContext }}
securityContext:
  {{- tpl (toYaml $.Values.securityContext) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.hostAliases" -}}
{{- if $.Values.hostAliases }}
hostAliases:
  {{- tpl (toYaml $.Values.hostAliases) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.imagePullSecrets" -}}
{{- if $.Values.imagePullSecrets }}
imagePullSecrets:
  {{- tpl (toYaml $.Values.imagePullSecrets) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.podSecurityContext" -}}
{{- if $.Values.podSecurityContext }}
securityContext:
  {{- tpl (toYaml $.Values.podSecurityContext) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.nodeSelector" -}}
{{- if $.Values.nodeSelector }}
nodeSelector:
  {{- tpl (toYaml $.Values.nodeSelector) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.strategy" -}}
{{- if $.Values.strategy }}
strategy:
  {{- tpl (toYaml $.Values.strategy) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.serviceAccountName" -}}
{{- if $.Values.serviceAccountName }}
serviceAccountName: {{ tpl $.Values.serviceAccountName $ }}
{{- end }}
{{- end }}

{{- define "template.ports" -}}
{{- if $.Values.ports }}
{{- range $.Values.ports }}
- containerPort: {{ tpl ((required "A valid 'containerPort' entry required!" .containerPort) | toString) $ }}
{{- if .name }}
  name: {{ tpl (.name | toString) $ }}
{{- end }} 
{{- if .protocol }}
  protocol: {{ tpl (.protocol | toString) $ }}
{{- end }} 
{{- if .hostPort }}
  hostPort: {{ tpl (.hostPort | toString) $ }}
{{- end }}  
{{- if .hostIP }}
  hostIP: {{ tpl (.hostIP | toString) $ }}
{{- end }}  
{{- end }}
{{- end }}
{{- end }}

{{- define "template.extraPorts" -}}
{{- if $.Values.extraPorts }}
{{- range $extraPortName, $extraPortValue := $.Values.extraPorts }}
{{- if not (eq ($extraPortValue.enabled | toString) "false") }}
- name: {{ tpl ($extraPortName | toString) $ }}
  containerPort: {{ tpl ((required "A valid 'containerPort' entry required!" $extraPortValue.containerPort) | toString) $ }}
{{- if $extraPortValue.protocol }}
  protocol: {{ tpl ($extraPortValue.protocol | toString) $ }}
{{- end }}  
{{- if $extraPortValue.hostPort }}
  hostPort: {{ tpl ($extraPortValue.hostPort | toString) $ }}
{{- end }}  
{{- if $extraPortValue.hostIP }}
  hostIP: {{ tpl ($extraPortValue.hostIP | toString) $ }}
{{- end }} 
{{- end }}
{{- end }}
{{- end }}
{{- end }}


{{- define "template.volumeMounts" -}}
{{- if $.Values.volumeMounts }}
## from $.Values.volumeMounts
{{ tpl (toYaml $.Values.volumeMounts) $ }}
{{- end }}
{{- end }}

{{- define "template.extraVolumeMounts" -}}
{{- if $.Values.extraVolumeMounts }}
{{- range $extraVolumeMountsName, $extraVolumeMountsValue := $.Values.extraVolumeMounts }}
{{- if not (eq ($extraVolumeMountsValue.enabled | toString) "false") }}
## from $.Values.extraVolumeMounts
- name: {{ tpl ($extraVolumeMountsName | toString) $ }}
  mountPath: {{ tpl ($extraVolumeMountsValue.mountPath | toString) $ }}
{{- if $extraVolumeMountsValue.mountPropagation }}
  mountPropagation: {{ tpl ($extraVolumeMountsValue.mountPropagation | toString) $ }}
{{- end }}
{{- if $extraVolumeMountsValue.readOnly }}
  readOnly: {{ tpl ($extraVolumeMountsValue.readOnly | toString) $ }}
{{- end }}
{{- if $extraVolumeMountsValue.subPath }}
  subPath: {{ tpl ($extraVolumeMountsValue.subPath | toString) $ }}
{{- end }} 
{{- if $extraVolumeMountsValue.subPathExpr }}
  subPathExpr: {{ tpl ($extraVolumeMountsValue.subPathExpr | toString) $ }}
{{- end }} 
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "template.volumes" -}}
{{- if $.Values.volumes }}
## from $.Values.volumes
{{ tpl (toYaml $.Values.volumes) $ }}
{{- end }}
{{- end }}

{{- define "template.extraVolumes" -}}
{{- if $.Values.extraVolumes }}
## from $.Values.extraVolumes
{{- range $extraVolumesName, $extraVolumesValue := $.Values.extraVolumes }}
{{- if not (eq ($extraVolumesValue.enabled | toString) "false") }}
- name: {{ tpl ($extraVolumesName | toString) $ }}
{{- if $extraVolumesValue.configMap }}
  configMap:
    {{ tpl (toYaml $extraVolumesValue.configMap) $ | nindent 4 }}
{{- end }}
{{- if $extraVolumesValue.secret }}
  secret:
    {{- tpl (toYaml $extraVolumesValue.secret) $ | nindent 4 }}
{{- end }}
{{- if $extraVolumesValue.hostPath }}
  hostPath:
    {{- tpl (toYaml $extraVolumesValue.hostPath) $ | nindent 4 }}
{{- end }}
{{- if $extraVolumesValue.projected }}
  projected:
    {{- tpl (toYaml $extraVolumesValue.projected) $ | nindent 4 }}
{{- end }}
{{- if $extraVolumesValue.persistentVolumeClaim }}
  persistentVolumeClaim:
    {{- tpl (toYaml $extraVolumesValue.persistentVolumeClaim) $ | nindent 4 }}
{{- end }}
{{- if $extraVolumesValue.storageos }}
  storageos:
    {{- tpl (toYaml $extraVolumesValue.storageos) $ | nindent 4 }}
{{- end }}
{{- if $extraVolumesValue.emptyDir }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "template.affinity" -}}
{{- if $.Values.affinity }}
affinity:
  {{- tpl (toYaml $.Values.affinity) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.tolerations" -}}
{{- if $.Values.tolerations }}
tolerations:
  {{- tpl (toYaml $.Values.tolerations) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.dnsPolicy" -}}
{{- if $.Values.dnsPolicy }}
dnsPolicy: {{ $.Values.dnsPolicy | default "ClusterFirst" }}
{{- end }}
{{- end }}

{{- define "template.dnsConfig" -}}
{{- if $.Values.dnsConfig }}
dnsConfig:
  {{- tpl (toYaml $.Values.dnsConfig) $ | nindent 2 }}
{{- end }}
{{- end }}


{{- define "template.imagePullPolicy" -}}
imagePullPolicy: {{ .Values.imagePullPolicy  | default "Always" }}
{{- end }}

{{- define "template.hostname" -}}
{{- if $.Values.hostname }}
hostname: {{ $.Values.hostname }}
{{- end }}
{{- end }}


{{- define "template.image" -}}
{{- if $.Values.imageOverride }}
image: {{ $.Values.imageOverride }}
{{- else if $.Values.image }}
image: {{ $.Values.image.registry }}/
      {{- $.Values.image.repository }}/
      {{- $.Values.image.name | default .Chart.Name }}:
      {{- $.Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}

{{- define "template.replicas" -}}
replicas: {{ $.Values.replicas | default $.Values.replicaCount | default "1" }}
{{- end }}

{{- define "template.annotationsChecksum" -}}
{{- if $.Values.configmaps }}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end }}
{{- if $.Values.secrets }}
checksum/secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
{{- end }}
{{- end }}

{{- define "template.annotations" -}}
{{- include "template.helmTemplateVersion" . }}
{{- if $.Values.annotations }}
{{ tpl (toYaml $.Values.annotations) $ }}
{{- end }}
{{- end }}

{{- define "template.rollout" -}}
{{- if not (eq ($.Values.rollout | toString) "false") }}
rollout: {{ randAlphaNum 12 | quote }}
{{- end }}
{{- end }}


{{- define "template.valuesLabels" -}}
{{- if $.Values.labels }}
{{ tpl (toYaml $.Values.labels) $ }}
{{- end }}
{{- end }}

{{- define "template.valuesMetadataLabels" -}}
{{- if $.Values.metadataLabels }}
{{ tpl (toYaml $.Values.metadataLabels) $ }}
{{- end }}
{{- end }}



{{- define "template.podManagementPolicy" -}}
podManagementPolicy: {{ $.Values.podManagementPolicy | default "OrderedReady" }} 
{{- end }}

{{- define "template.serviceName" -}}
serviceName: {{ tpl ((required "A valid 'serviceName' entry required!" $.Values.serviceName) | toString) $ }} 
{{- end }}


{{- define "template.updateStrategy" -}}
{{- if $.Values.updateStrategy }}
updateStrategy:
  {{- tpl (toYaml $.Values.updateStrategy) $ | nindent 2 }}
{{- end }}
{{- end }}

{{- define "template.volumeClaimTemplates" -}}
{{- if $.Values.volumeClaimTemplates }}
volumeClaimTemplates:
  {{- tpl (toYaml $.Values.volumeClaimTemplates) $ | nindent 2 }}
{{- end }}
{{- end }}








{{- define "template.initContainers" -}}
{{- range $initContainerName, $initContainerValue := $.Values.initContainers }}
{{- if not (eq ($initContainerValue.enabled | toString) "false") }}
- name: {{ tpl $initContainerName $ | squote }}
  imagePullPolicy: {{ $initContainerValue.imagePullPolicy | default $.Values.imagePullPolicy  | default "Always" }}
{{- if $initContainerValue.imageOverride }}
  image: {{ $initContainerValue.imageOverride }}
{{- else if $initContainerValue.image }}
  image: {{ $initContainerValue.image.registry | default $.Values.image.registry }}/
        {{- $initContainerValue.image.repository | default $.Values.image.repository }}/
        {{- $initContainerValue.image.name | default $.Values.image.name }}:
        {{- $initContainerValue.image.tag | default $.Values.image.tag | default $.Chart.AppVersion }}
{{- end }}
{{- if $initContainerValue.command }}
  command: 
    {{- tpl (toYaml $initContainerValue.command) $ | nindent 4 }}
{{- end }}
{{- if $initContainerValue.args }}
  args:
    {{- tpl (toYaml $initContainerValue.args) $ | nindent 4 }}
{{- end }}
{{- if $initContainerValue.resources }}
  resources:
    {{- tpl (toYaml $initContainerValue.resources) $ | nindent 4 }}
{{- end }}
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
  {{- if $initContainerValue.env }}
    ## from initContainers..env
    {{- tpl (toYaml $initContainerValue.env) $ | nindent 4 }}
  {{- end }}
  {{- if $initContainerValue.extraEnv }}
    {{- range $extraEnvName, $extraEnvValue := $initContainerValue.extraEnv }}
    ## from initContainers..extraEnv
    - name: {{ $extraEnvName }}
      value: {{ tpl $extraEnvValue $ | squote }}
    {{- end }}
  {{- end }}
  {{- if $initContainerValue.extraEnvVars }}
    {{- range $extraEnvVarsName, $extraEnvVarsValue := $initContainerValue.extraEnvVars }}
    ## from initContainers..extraEnvVars
    - name: {{ $extraEnvVarsName }}
      value: {{ tpl $extraEnvVarsValue $ | quote }}
    {{- end }}
  {{- end }}
{{- if $initContainerValue.envFrom }}
  envFrom:
    {{- tpl (toYaml $initContainerValue.envFrom) $ | nindent 4 }}
{{- end }}
{{- if $initContainerValue.securityContext }}
  securityContext:
    {{- tpl (toYaml $initContainerValue.securityContext) $ | nindent 4 }}
{{- end }}
{{- if or $initContainerValue.volumeMounts $initContainerValue.extraVolumeMounts }}
  volumeMounts:
  {{- if $initContainerValue.volumeMounts }}
    ## from initContainers..volumeMounts
    {{- tpl (toYaml $initContainerValue.volumeMounts) $ | nindent 4 }}
  {{- end }}
  {{- if $initContainerValue.extraVolumeMounts }}
  {{- range $extraVolumeMountsName, $extraVolumeMountsValue := $initContainerValue.extraVolumeMounts }}
  {{- if not (eq ($extraVolumeMountsValue.enabled | toString) "false") }}
    ## from initContainers..extraVolumeMounts
    - name: {{ tpl ($extraVolumeMountsName | toString) $ }}
      mountPath: {{ tpl ($extraVolumeMountsValue.mountPath | toString) $ }}
    {{- if $extraVolumeMountsValue.mountPropagation }}
      mountPropagation: {{ tpl ($extraVolumeMountsValue.mountPropagation | toString) $ }}
    {{- end }}
    {{- if $extraVolumeMountsValue.readOnly }}
      readOnly: {{ tpl ($extraVolumeMountsValue.readOnly | toString) $ }}
    {{- end }}
    {{- if $extraVolumeMountsValue.subPath }}
      subPath: {{ tpl ($extraVolumeMountsValue.subPath | toString) $ }}
    {{- end }} 
    {{- if $extraVolumeMountsValue.subPathExpr }}
      subPathExpr: {{ tpl ($extraVolumeMountsValue.subPathExpr | toString) $ }}
    {{- end }} 
  {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}



{{- define "template.extraContainers" -}}
{{- if $.Values.extraContainers }}
{{- range $extraContainersName, $extraContainersValue := $.Values.extraContainers }}
{{- if not (eq ($extraContainersValue.enabled | toString) "false") }}
- name: {{ tpl $extraContainersName $ | squote }}
  imagePullPolicy: {{ $extraContainersValue.imagePullPolicy | default $.Values.imagePullPolicy  | default "Always" }}
{{- if $extraContainersValue.imageOverride }}
  image: {{ $extraContainersValue.imageOverride }}
{{- else if $extraContainersValue.image }}
  image: {{ $extraContainersValue.image.registry | default $.Values.image.registry }}/
        {{- $extraContainersValue.image.repository | default $.Values.image.repository }}/
        {{- $extraContainersValue.image.name | default $.Values.image.name | default $.Values.name | default $.Chart.Name }}:
        {{- $extraContainersValue.image.tag | default $.Values.image.tag | default $.Chart.AppVersion }}
{{- end }}

{{- if $extraContainersValue.lifecycle }}
  lifecycle:
    {{- tpl (toYaml $extraContainersValue.lifecycle) $ | nindent 4 }}
{{- end }}


{{- if $extraContainersValue.command }}
  command: 
    {{- tpl (toYaml $extraContainersValue.command) $ | nindent 4 }}
{{- end }}
{{- if $extraContainersValue.args }}
  args:
    {{- tpl (toYaml $extraContainersValue.args) $ | nindent 4 }}
{{- end }}
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
  {{- if $extraContainersValue.env }}
    ## from extraContainers..env
    {{- tpl (toYaml $extraContainersValue.env) $ | nindent 4 }}
  {{- end }}
  {{- if $extraContainersValue.extraEnv }}
    {{- range $extraEnvName, $extraEnvValue := $extraContainersValue.extraEnv }}
    ## from extraContainers..extraEnv
    - name: {{ $extraEnvName }}
      value: {{ tpl $extraEnvValue $ | squote }}
    {{- end }}
  {{- end }}
  {{- if $extraContainersValue.extraEnvVars }}
    ## from extraContainers..extraEnvVars
    {{- range $extraEnvVarsName, $extraEnvVarsValue := $extraContainersValue.extraEnvVars }}
    - name: {{ $extraEnvVarsName }}
      value: {{ tpl $extraEnvVarsValue $ | quote }}
    {{- end }}
  {{- end }}
{{- if $extraContainersValue.envFrom }}
  envFrom:
    {{- tpl (toYaml $extraContainersValue.envFrom) $ | nindent 4 }}
{{- end }}

{{- if or $extraContainersValue.ports $extraContainersValue.extraPorts }}
  ports:
{{- if $extraContainersValue.ports }}
    ## from extraContainers..ports
  {{- range $extraContainersValue.ports }}
    - containerPort: {{ tpl ((required "A valid 'containerPort' entry required!" .containerPort) | toString) $ }}
    {{- if .name }}
      name: {{ tpl (.name | toString) $ }}
    {{- end }} 
    {{- if .protocol }}
      protocol: {{ tpl (.protocol | toString) $ }}
    {{- end }} 
    {{- if .hostPort }}
      hostPort: {{ tpl (.hostPort | toString) $ }}
    {{- end }}  
    {{- if .hostIP }}
      hostIP: {{ tpl (.hostIP | toString) $ }}
    {{- end }}  
  {{- end }}
{{- end }}
{{- if $extraContainersValue.extraPorts }}
    ## from extraContainers..extraPorts
  {{- range $extraPortName, $extraPortValue := $extraContainersValue.extraPorts }}
  {{- if not (eq ($extraPortValue.enabled | toString) "false") }}
    - containerPort: {{ tpl ((required "A valid 'containerPort' entry required!" $extraPortValue.containerPort) | toString) $ }}
      name: {{ tpl ($extraPortName | toString) $ }}
    {{- if $extraPortValue.protocol }}
      protocol: {{ tpl ($extraPortValue.protocol | toString) $ }}
    {{- end }}  
    {{- if $extraPortValue.hostPort }}
      hostPort: {{ tpl ($extraPortValue.hostPort | toString) $ }}
    {{- end }}  
    {{- if $extraPortValue.hostIP }}
      hostIP: {{ tpl ($extraPortValue.hostIP | toString) $ }}
    {{- end }} 
  {{- end }}
{{- end }}
{{- end }}
{{- end }}      

{{- if $extraContainersValue.livenessProbe }}
  livenessProbe:
    {{- tpl (toYaml $extraContainersValue.livenessProbe) $ | nindent 4 }}
{{- end }}
{{- if $extraContainersValue.readinessProbe }}
  readinessProbe:
    {{- tpl (toYaml $extraContainersValue.readinessProbe) $ | nindent 4 }}
{{- end }}
{{- if $extraContainersValue.resources }}
  resources:
    {{- tpl (toYaml $extraContainersValue.resources) $ | nindent 4 }}
{{- end }}
{{- if $extraContainersValue.securityContext }}
  securityContext:
    {{- tpl (toYaml $extraContainersValue.securityContext) $ | nindent 4 }}
{{- end }}
{{- if or $extraContainersValue.volumeMounts $extraContainersValue.extraVolumeMounts}}
  volumeMounts:
  {{- if or $extraContainersValue.volumeMounts $extraContainersValue.extraVolumeMounts}}
    ## from extraContainers.volumeMounts
    {{- tpl (toYaml $extraContainersValue.volumeMounts) $ | nindent 4 }}
  {{- end }}
  {{- if $extraContainersValue.extraVolumeMounts }}
  {{- range $extraVolumeMountsName, $extraVolumeMountsValue := $extraContainersValue.extraVolumeMounts }}
  {{- if not (eq ($extraVolumeMountsValue.enabled | toString) "false") }}
    ## from extraContainers.extraVolumeMounts
    - name: {{ tpl ($extraVolumeMountsName | toString) $ }}
      mountPath: {{ tpl ($extraVolumeMountsValue.mountPath | toString) $ }}
    {{- if $extraVolumeMountsValue.mountPropagation }}
      mountPropagation: {{ tpl ($extraVolumeMountsValue.mountPropagation | toString) $ }}
    {{- end }}
    {{- if $extraVolumeMountsValue.readOnly }}
      readOnly: {{ tpl ($extraVolumeMountsValue.readOnly | toString) $ }}
    {{- end }}
    {{- if $extraVolumeMountsValue.subPath }}
      subPath: {{ tpl ($extraVolumeMountsValue.subPath | toString) $ }}
    {{- end }} 
    {{- if $extraVolumeMountsValue.subPathExpr }}
      subPathExpr: {{ tpl ($extraVolumeMountsValue.subPathExpr | toString) $ }}
    {{- end }} 
  {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}


{{- define "template.terminationGracePeriodSeconds" -}}
{{- if $.Values.terminationGracePeriodSeconds }}
terminationGracePeriodSeconds: {{ $.Values.terminationGracePeriodSeconds }}
{{- end }}
{{- end }}

{{- define "template.lifecycle" -}}
{{- if $.Values.lifecycle }}
{{- if not (eq ($.Values.lifecycle.enabled | toString) "false") }}
lifecycle:
  {{- if $.Values.lifecycle.postStart }}
  {{- if not (eq ($.Values.lifecycle.postStart.enabled | toString) "false") }}
  postStart:
    {{- if $.Values.lifecycle.postStart.exec }}
    exec:
    {{- tpl (toYaml $.Values.lifecycle.postStart.exec) $ | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- end }}

  {{- if $.Values.lifecycle.preStop }}
  {{- if not (eq ($.Values.lifecycle.preStop.enabled | toString) "false") }}
  preStop:
    {{- if $.Values.lifecycle.preStop.exec }}
    exec:
    {{- tpl (toYaml $.Values.lifecycle.preStop.exec) $ | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
