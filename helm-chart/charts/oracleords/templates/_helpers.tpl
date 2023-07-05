{{/*
Expand the name of the chart.
*/}}
{{- define "oracleords.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oracleords.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "oracleords.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "oracleords.labels" -}}
helm.sh/chart: {{ include "oracleords.chart" . }}
{{ include "oracleords.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "oracleords.selectorLabels" -}}
app.kubernetes.io/name: {{ include "oracleords.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "oracleords.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "oracleords.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/* Expand ORDS Variables using a template */}}
{{- define "oracle-ords-env" }}
- name: ORACLE_ADMIN_USER
  value: "SYS"
- name: ORACLE_SERVICE
  value: {{ default "FREEPDB1" .Values.global.oracle_pdb | quote }}
- name: ORACLE_HOST
  value: "oracle23c-service.{{ .Release.Namespace }}.svc.cluster.local"
- name: ORACLE_PORT
  value: "1521"
- name: ORDS_USER
  value: "ORDS_PUBLIC_USER"
- name: ORDS_PWD
  valueFrom:
    secretKeyRef:
      name: ords-pwd
      key: ords_pwd
- name: ORACLE_PWD
  valueFrom:
    secretKeyRef:
      name: oracle-pwd
      key: oracle_pwd
- name: ORDS_HTTPS_PORT
  value: "8443"
- name: ORDS_HTTP_PORT
  value: "8080"
- name: ORDS_CERT
  value: "/etc/ords/keystore/test.der"
- name: ORDS_CERT_KEY
  value: "/etc/ords/keystore/test-key.der"
{{- end -}}

{{/* Expand DBTool Variables using a template */}}
{{- define "oracle-dbtool-env" }}
env:
  - name: ORACLE_SERVICE
    value: "freepdb1"
  - name: ORACLE_HOST
    value: "oracle23c-service.{{ .Release.Namespace }}.svc.cluster.local"
  - name: ORACLE_PORT
    value: "1521"
  - name: MONGO_USER_NAME
    value: "MONGO_TEST"
  - name: MONGO_USER_PWD
    value: "MyPassword1!"
  - name: ORACLE_PWD
    valueFrom:
      secretKeyRef:
        name: oracle-pwd
        key: oracle_pwd
{{- end -}}


{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}