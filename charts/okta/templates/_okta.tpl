{{/*
_okta.tpl contains helper templates for the okta chart
*/}}

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
