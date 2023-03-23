{{/*
_utils.tpl is the same for all commvault components. Any change in this file should be copied to the _utils.tpl in all the components.
*/}}

{{/*
cv.utils.formatYAML is a generic function that will iterate over the input specifications list and output the yaml.
It also supports string based values to be templates themselves.
So just as an example you can have the value of additionalPodspecs.zone set to some global value like so:

additionalPodspecs:
  nodeSelector: 
    zone: "{{ .Values.global.zone }}"

The usequotes parameter is for annotations which require the values to be in quotes if they are integers
*/}}
{{- define "cv.utils.formatYAML" }}
{{- $specs := index . 0 }}
{{- $root := index . 1 }}
{{- $indent := index . 2 }}
{{- $useQuotes := index . 3 }}
{{- $indent2 := add $indent 2 }}
{{- range $k, $v := $specs }} 
{{- if kindIs "invalid" $v }}
{{- else if (kindIs "map" $v) -}}
{{ $k | nindent $indent }}:
{{- include "cv.utils.formatYAML" (list $v $root (int $indent2) $useQuotes ) }}
{{- else if (kindIs "slice" $v) -}}
{{ $k | nindent $indent }}:
{{- toYaml $v | nindent (int $indent2) -}}
{{- else if or (kindIs "float64" $v) (kindIs "int64" $v) (kindIs "bool" $v) -}}
{{- if $useQuotes -}}
{{ $k | nindent $indent }}: {{ $v | quote }}
{{- else -}}
{{ $k | nindent $indent }}: {{ $v }}
{{- end -}}
{{- else if kindIs "string" $v -}}
{{ $k | nindent $indent }}: {{ tpl $v $root }}
{{- else }}
{{- toYaml $v | nindent $indent -}}
{{- end }}
{{- end }}
{{- end -}}

{{/*
cv.utils.getCombinedYaml is a utility function that will merge 2 sections of values from global and local where local values will override global values if supplied
For example if the following values are defined
# globals.yaml
global:
  annotations:
    controller.kubernetes.io/pod-deletion-cost: "50"

# values.yaml
annotations:
  topology.kubernetes.io/zone: "useast"
  service.beta.kubernetes.io/azure-dns-label-name: "{{ .Values.clientName }}"

then combined annotations will be
annotations:
  controller.kubernetes.io/pod-deletion-cost: "50"
  topology.kubernetes.io/zone: "useast"
  service.beta.kubernetes.io/azure-dns-label-name: clientName

The values can be templatized strings themselves, as shown for dns label annotation, to make it more flexible
*/}}
{{- define "cv.utils.getCombinedYaml" }}
{{- $localValues := index . 0 }}
{{- $globalValues := index . 1 }}
{{- $root := index . 2 }}
{{- $indent := index . 3 }}
{{- $useQuotes := index . 4 }}
{{- if or $globalValues $localValues }}
{{- if and $globalValues $localValues -}}
{{- $mergedValues := mustMergeOverwrite (dict) $globalValues $localValues -}}
{{- include "cv.utils.formatYAML" (list $mergedValues $root $indent $useQuotes ) }}
{{- else if $globalValues -}}
{{- include "cv.utils.formatYAML" (list $globalValues $root $indent $useQuotes ) }}
{{- else -}}
{{- include "cv.utils.formatYAML" (list $localValues $root $indent $useQuotes ) }}
{{- end -}}
{{- end -}}
{{ end }}


{{/*
cv.utils.mergelist is a utility function that will merge 2 lists of values from global and local
For example if the following values are defined
# globals.yaml
volumes:
  - name: vol1
    mountPath: /var/opt/vol1
    subPath: vol1
    size: 1Mi
    storageClass: abc

# values.yaml
volumes:
  - name: vol2
    mountPath: /var/opt/vol2
    subPath: vol2
    size: 1Mi
    storageClass: abc

then combined volumes array will be
volumes:
  - name: vol1
    mountPath: /var/opt/vol1
    subPath: vol1
    size: 1Mi
    storageClass: abc
  - name: vol2
    mountPath: /var/opt/vol2
    subPath: vol2
    size: 1Mi
    storageClass: abc

Note that the top level "volumes:" level in the combined array is important for the array to be a properly formatted yaml.
*/}}
{{- define "cv.util.mergelist" }}
{{- $list1 := index . 0 }}
{{- $list2 := index . 1 }}
{{- $type := index . 2 }}
{{- if and $list1 $list2 }}
{{ $type }}:
{{ toYaml (concat $list1 $list2) | indent 2 }}
{{- else if $list1 }}
{{ $type }}:
{{ toYaml $list1  | indent 2}}
{{- else if $list2 }}
{{ $type }}:
{{ toYaml $list2  | indent 2}}
{{- end }}
{{- end }}


{{/*
Enforces the format of the image tag. It must be of the format <version>.<release>.* example: 11.30.1
The version and feature release may be used to change how objects are deployed for a given version and release
For now the version number 11 is enforced
*/}}
{{- define "cv.utils.validateVersionAndRelease" }}
{{- $tag := required "image.tag or global.image.tag is required" (or (.Values.image).tag ((.Values.global).image).tag) }}
{{- if regexMatch "^\\d+[.]\\d+[.]" $tag }}
    {{- $numbers := regexFindAll  "(\\d+)" $tag 2 }}
    {{- $version := atoi (first $numbers) }}
    {{- $servicepack := atoi (last $numbers) }}
    {{- if or (lt $version 11) (gt $version 11) }}
    {{- fail (printf "Incorrect version number %d " $version)}}
    {{- end }}
{{- else }}
    {{- fail (printf "Incorrect tag %s. Must be of format <version>.<release>.*" $tag)}}
{{- end }}
{{- end }}


{{/*
Returns the number 11 from sample tag 11.30.1
This function assumes that validateVersionAndRelease has been called to validate tag value correctness
*/}}
{{- define "cv.utils.getVersion" }}
{{- $tag := (or (.Values.image).tag ((.Values.global).image).tag) }}
{{- atoi (first (regexFindAll  "(\\d+)" $tag 2)) }}
{{- end }}

{{/*
Returns the number 30 from sample tag 11.30.1
This function assumes that validateVersionAndRelease has been called to validate tag value correctness
*/}}
{{- define "cv.utils.getFeatureRelease" }}
{{- $tag := (or (.Values.image).tag ((.Values.global).image).tag) }}
{{- atoi (last (regexFindAll  "(\\d+)" $tag 2)) }}
{{- end }}

{{/*
Returns "true" if the image tag's version and FR is at least what is given as inputs to this function. This is how it can be used

  {{- if eq (include "cv.utils.isMinVersion" (list . 11 34)) "true" }}
  // TRUE
  {{ else }}
  // FALSE
  {{ end }}

*/}}
{{- define "cv.utils.isMinVersion" }}
{{- $root := index . 0 }}
{{- $version := index . 1 }}
{{- $featurerelease := index . 2 }}
{{- if and (ge (atoi ( include "cv.utils.getVersion" $root )) $version ) (ge (atoi ( include "cv.utils.getFeatureRelease" $root )) $featurerelease) }}
{{- printf "true" }}
{{- else }}
{{- printf "false" }}
{{- end }}
{{- end }}
