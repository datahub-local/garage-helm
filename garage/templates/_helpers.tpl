{{/*
Expand the name of the chart.
*/}}
{{- define "garage.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "garage.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret
*/}}
{{- define "garage.secretName" -}}
{{- if .Values.garage.secret.name -}}
{{- .Values.garage.secret.name -}}
{{- else -}}
{{- printf "%s-secret" (include "garage.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "garage.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "garage.labels" -}}
{{ include "garage.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ with .Values.commonLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "garage.selectorLabels" -}}
app.kubernetes.io/name: {{ include "garage.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: garage
{{- end }}

{{/*
WebUI Selector labels
*/}}
{{- define "garage.webui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "garage.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: webui
{{- end }}

{{/*
WebUI labels
*/}}
{{- define "garage.webui.labels" -}}
{{ include "garage.webui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ with .Values.commonLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "garage.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "garage.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Garage configuration file content
*/}}
{{- define "garage.config.content" -}}
{{- if .Values.garage.garageTomlString }}
{{- tpl (index (index .Values.garage) "garageTomlString") $ }}
{{- else }}
metadata_dir = "/mnt/meta"
data_dir = "/mnt/data"

db_engine = "{{ .Values.garage.dbEngine }}"

block_size = {{ .Values.garage.blockSize }}

replication_factor = {{ .Values.garage.replicationFactor }}
consistency_mode = "{{ .Values.garage.consistencyMode }}"

compression_level = {{ .Values.garage.compressionLevel }}

{{- if .Values.garage.metadataAutoSnapshotInterval }}
metadata_auto_snapshot_interval = {{ .Values.garage.metadataAutoSnapshotInterval | quote }}
{{- end }}

rpc_bind_addr = "{{ .Values.garage.rpc.bindAddr }}"

bootstrap_peers = {{ .Values.garage.bootstrapPeers }}

[kubernetes_discovery]
namespace = "{{ .Release.Namespace }}"
service_name = "{{ include "garage.fullname" . }}"
skip_crd = {{ .Values.garage.kubernetesSkipCrd }}

[s3_api]
s3_region = "{{ .Values.garage.s3.api.region }}"
api_bind_addr = "[::]:3900"
root_domain = "{{ .Values.garage.s3.api.rootDomain }}"

[s3_web]
bind_addr = "[::]:3902"
root_domain = "{{ .Values.garage.s3.web.rootDomain }}"
index = "{{ .Values.garage.s3.web.index }}"
add_host_to_metrics = true

[admin]
api_bind_addr = "[::]:3903"
{{- if .Values.monitoring.tracing.sink }}
trace_sink = "{{ .Values.monitoring.tracing.sink }}"
{{- end }}
{{- end }}
{{- end }}

{{/*
Garage secret data content
*/}}
{{- define "garage.secret.content" -}}
rpcSecret: {{ .Values.garage.secret.rpcSecret | default (include "jupyterhub.randHex" 64) | b64enc | quote }}
adminToken: {{ .Values.garage.secret.adminToken | default (include "jupyterhub.randHex" 64) | b64enc | quote }}

{{- if (and (.Values.webui.enabled) (.Values.webui.auth.enabled)) }}
{{- if not .Values.webui.auth.existingSecret }}
{{- if .Values.webui.auth.userPassHash }}
webuiAuthUserPass: {{ .Values.webui.auth.userPassHash | b64enc | quote }}
{{- else }}
{{- fail "webui.auth.userPassHash is required when auth is enabled. Generate it with: htpasswd -nbBC 10 'username' 'password'" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
    Returns given number of random Hex characters.
    In practice, it generates up to 100 randAlphaNum strings
    that are filtered from non-hex characters and augmented
    to the resulting string that is finally trimmed down.
*/}}
{{- define "jupyterhub.randHex" -}}
    {{- $result := "" }}
    {{- range $i := until 100 }}
        {{- if lt (len $result) . }}
            {{- $rand_list := randAlphaNum . | splitList "" -}}
            {{- $reduced_list := without $rand_list "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" }}
            {{- $rand_string := join "" $reduced_list }}
            {{- $result = print $result $rand_string -}}
        {{- end }}
    {{- end }}
    {{- $result | trunc . }}
{{- end }}
