{{/*
_okta.tpl contains helper templates for the okta chart
*/}}

{{/*
okta.validateInputs performs comprehensive input validation for the okta chart.
This should be called at the beginning of any template that renders resources.
*/}}
{{- define "okta.validateInputs" -}}
{{/* Validate global settings */}}
{{- if not (.Values.global).azureWorkloadIdentityClientId -}}
{{- fail "global.azureWorkloadIdentityClientId is required" -}}
{{- end -}}

{{/* Validate serviceAccount */}}
{{- if not (.Values.serviceAccount).name -}}
{{- fail "serviceAccount.name is required" -}}
{{- end -}}

{{/* Validate triggerAuth */}}
{{- if not (.Values.triggerAuth).name -}}
{{- fail "triggerAuth.name is required" -}}
{{- end -}}

{{/* Validate scaledjobs */}}
{{- if not .Values.scaledjobs -}}
{{- fail "scaledjobs is required and must contain at least one job definition" -}}
{{- end -}}

{{- if not (kindIs "slice" .Values.scaledjobs) -}}
{{- fail "scaledjobs must be a list/array of job definitions" -}}
{{- end -}}

{{- if eq (len .Values.scaledjobs) 0 -}}
{{- fail "scaledjobs must contain at least one job definition" -}}
{{- end -}}

{{/* Validate each scaled job */}}
{{- range $index, $job := .Values.scaledjobs -}}
{{- if not $job.name -}}
{{- fail (printf "scaledjobs[%d].name is required" $index) -}}
{{- end -}}

{{- if not $job.image -}}
{{- fail (printf "scaledjobs[%d].image is required (job: %s)" $index ($job.name | default "unnamed")) -}}
{{- end -}}

{{- if not $job.queueName -}}
{{- fail (printf "scaledjobs[%d].queueName is required (job: %s)" $index ($job.name | default "unnamed")) -}}
{{- end -}}

{{/* Validate serviceBusNamespace - must be specified either globally or per job */}}
{{- if and (not $job.serviceBusNamespace) (not ($.Values.global).serviceBusNamespace) -}}
{{- fail (printf "scaledjobs[%d].serviceBusNamespace or global.serviceBusNamespace is required (job: %s)" $index ($job.name | default "unnamed")) -}}
{{- end -}}

{{/* Validate env entries if provided */}}
{{- if $job.env -}}
{{- if not (kindIs "slice" $job.env) -}}
{{- fail (printf "scaledjobs[%d].env must be a list (job: %s)" $index ($job.name | default "unnamed")) -}}
{{- end -}}
{{- range $envIndex, $envVar := $job.env -}}
{{- if not $envVar.name -}}
{{- fail (printf "scaledjobs[%d].env[%d].name is required (job: %s)" $index $envIndex ($job.name | default "unnamed")) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate numeric fields if provided */}}
{{- if and (hasKey $job "pollingInterval") (not (kindIs "float64" $job.pollingInterval)) (not (kindIs "int64" $job.pollingInterval)) (not (kindIs "int" $job.pollingInterval)) -}}
{{- fail (printf "scaledjobs[%d].pollingInterval must be a number (job: %s)" $index ($job.name | default "unnamed")) -}}
{{- end -}}

{{- if and (hasKey $job "maxReplicaCount") (not (kindIs "float64" $job.maxReplicaCount)) (not (kindIs "int64" $job.maxReplicaCount)) (not (kindIs "int" $job.maxReplicaCount)) -}}
{{- fail (printf "scaledjobs[%d].maxReplicaCount must be a number (job: %s)" $index ($job.name | default "unnamed")) -}}
{{- end -}}

{{- if and (hasKey $job "messageCount") (not (kindIs "float64" $job.messageCount)) (not (kindIs "int64" $job.messageCount)) (not (kindIs "int" $job.messageCount)) -}}
{{- fail (printf "scaledjobs[%d].messageCount must be a number (job: %s)" $index ($job.name | default "unnamed")) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
okta.namespace returns the namespace to use for resources.
Uses global.namespace if defined, otherwise falls back to Release.Namespace.
*/}}
{{- define "okta.namespace" -}}
{{- if (.Values.global).namespace -}}
{{ (.Values.global).namespace }}
{{- else -}}
{{ .Release.Namespace }}
{{- end -}}
{{- end -}}

{{/*
okta.serviceAccountName returns the service account name.
*/}}
{{- define "okta.serviceAccountName" -}}
{{- required "serviceAccount.name is required" (.Values.serviceAccount).name -}}
{{- end -}}

{{/*
okta.triggerAuthName returns the trigger authentication name.
*/}}
{{- define "okta.triggerAuthName" -}}
{{- required "triggerAuth.name is required" (.Values.triggerAuth).name -}}
{{- end -}}

{{/*
okta.workloadIdentityClientId returns the Azure Workload Identity Client ID.
*/}}
{{- define "okta.workloadIdentityClientId" -}}
{{- required "global.azureWorkloadIdentityClientId is required" (.Values.global).azureWorkloadIdentityClientId -}}
{{- end -}}

{{/*
okta.podIdentityProvider returns the pod identity provider.
Uses triggerAuth.podIdentity.provider if defined, otherwise falls back to defaults.
*/}}
{{- define "okta.podIdentityProvider" -}}
{{- $defaults := (fromYaml (.Files.Get "defaults.yaml")) -}}
{{- or ((.Values.triggerAuth).podIdentity).provider (($defaults.triggerAuth).podIdentity).provider "azure-workload" -}}
{{- end -}}

{{/*
okta.defaultValue is a helper to get a value with fallback to defaults.yaml.
Usage: {{ include "okta.defaultValue" (list . "pollingInterval" 30) }}
*/}}
{{- define "okta.defaultValue" -}}
{{- $root := index . 0 -}}
{{- $key := index . 1 -}}
{{- $fallback := index . 2 -}}
{{- $defaults := (fromYaml ($root.Files.Get "defaults.yaml")) -}}
{{- or (index $defaults $key) $fallback -}}
{{- end -}}
