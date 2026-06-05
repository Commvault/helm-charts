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
Returns the tag of the image
*/}}
{{- define "cv.utils.getTag" }}
{{- $tag := "" }}
{{- if (.Values.image).location -}}
{{- $tag = last (splitList ":" (.Values.image).location) }}
{{- else -}}
{{- $tag = required "image.tag, global.image.tag or image.location is required" (or (.Values.image).tag ((.Values.global).image).tag) }}
{{- end }}
{{- $tag }}
{{- end }}


{{/*
Enforces the format of the image tag. It must be of the format <version>.<release>.* example: 11.30.1
The version and feature release may be used to change how objects are deployed for a given version and release
For now the version number 11 is enforced
*/}}
{{- define "cv.utils.validateVersionAndRelease" }}
{{- $tag := include "cv.utils.getTag" . }}
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
{{- $tag := include "cv.utils.getTag" . }}
{{- atoi (first (regexFindAll  "(\\d+)" $tag 2)) }}
{{- end }}

{{/*
Returns the number 30 from sample tag 11.30.1
This function assumes that validateVersionAndRelease has been called to validate tag value correctness
*/}}
{{- define "cv.utils.getFeatureRelease" }}
{{- $tag := include "cv.utils.getTag" . }}
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

{{/*
Finds the appropriate oem id to use.
Either explicit oem id is passed in as parameter or it will be assumed based on feature release

This was an if condition added earlier to determine oemid based on feature release
but no longer relevant
{{- if eq (len $release) 4 }}
{{- $oemid = "119" }}
{{- end }}
*/}}
{{- define "cv.utils.getOemId" }}
{{- $release := include "cv.utils.getFeatureRelease" . }}
{{- $oemid := "1" }}
{{- $oemid = or .Values.oemid ((.Values).global).oemid $oemid }}
{{- quote $oemid }}
{{- end }}


{{/*
Returns either commvault or metallic depending on the oem id
*/}}
{{- define "cv.utils.getOemPath" }}
{{- $oemid := include "cv.utils.getOemId" . }}
{{- if eq $oemid "\"119\"" }}
{{- "metallic" }}
{{- else }}
{{- "commvault" }}
{{- end }}
{{- end }}

{{/*
Returns the third number (CU pack) from a sample tag 11.42.105.Rev1425 -> 105
This function assumes that validateVersionAndRelease has been called to validate tag value correctness.
If the tag has only two parts (e.g. 11.42) it returns 0.
*/}}
{{- define "cv.utils.getCUPack" }}
{{- $tag := "" }}
{{- if (.Values.image).location -}}
{{- $tag = last (splitList ":" (.Values.image).location) }}
{{- else -}}
{{- $tag = or (.Values.image).tag ((.Values.global).image).tag "" }}
{{- end }}
{{- $numbers := regexFindAll "(\\d+)" $tag -1 }}
{{- if ge (len $numbers) 3 }}
{{- atoi (index $numbers 2) }}
{{- else }}
{{- 0 }}
{{- end }}
{{- end }}

{{/*
Returns "true" if the image tag's version, FR and CU pack is at least what is given as inputs.
This is a 3-part (major.FR.CU) comparison. Usage:

  {{- if eq (include "cv.utils.isMinVersion3" (list . 11 42 105)) "true" }}

Extracts the tag directly (nil-safe, no required) so it is safe to call before validateVersionAndRelease.
*/}}
{{- define "cv.utils.isMinVersion3" }}
{{- $root := index . 0 }}
{{- $version := index . 1 }}
{{- $featurerelease := index . 2 }}
{{- $cupack := index . 3 }}
{{- $tag := "" }}
{{- if ($root.Values.image).location -}}
{{- $tag = last (splitList ":" ($root.Values.image).location) }}
{{- else -}}
{{- $tag = or ($root.Values.image).tag (($root.Values.global).image).tag "" }}
{{- end }}
{{- $result := "false" }}
{{- if $tag }}
{{- $numbers := regexFindAll "(\\d+)" $tag -1 }}
{{- if ge (len $numbers) 3 }}
{{- $curVersion := atoi (index $numbers 0) }}
{{- $curFR := atoi (index $numbers 1) }}
{{- $curCU := atoi (index $numbers 2) }}
{{- if gt $curVersion $version }}
{{- $result = "true" }}
{{- else if eq $curVersion $version }}
{{- if gt $curFR $featurerelease }}
{{- $result = "true" }}
{{- else if eq $curFR $featurerelease }}
{{- if ge $curCU $cupack }}
{{- $result = "true" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- $result }}
{{- end }}

{{/*
Determines the install layout version ("v1" or "v2") for path resolution.

v1 = legacy paths under /opt/commvault, /opt/commvaultDB, /etc/CommVaultRegistry, etc.
v2 = standardized paths under /var/opt/commvault/Instance001/...

The standardization landed in SP42 CU105 (11.42.105). The boundary is captured here in a
single place so all path helpers stay consistent.

Priority order (so existing data is never stranded on an upgrade/reinstall):
  1. global.installLayoutVersion: v1|v2  -> explicit override
  2. Existing Deployment/StatefulSet carries annotation commvault.com/install-layout -> persisted layout
  3. No deployment, but the certsandlogs PVC already exists -> v1 (retained data from a prior v1 install)
  4. No deployment, no PVC, image >= 11.42.105 -> v2 (truly fresh install on a migrated image)
  5. Everything else -> v1 (safe default)
*/}}
{{- define "cv.installLayoutVersion" }}
{{- $override := or ((.Values).global).installLayoutVersion .Values.installLayoutVersion }}
{{- if $override }}
{{- $override }}
{{- else }}
{{- $statefulset := or .Values.statefulset ((.Values).global).statefulset }}
{{- $objectname := include "cv.metadataname" . }}
{{- $namespace := include "cv.namespace" . }}
{{- $kind := ternary "StatefulSet" "Deployment" (not (not $statefulset)) }}
{{- $existing := lookup "apps/v1" $kind $namespace $objectname }}
{{- if $existing }}
{{- $annotations := (($existing.metadata).annotations) | default dict }}
{{- $layout := get $annotations "commvault.com/install-layout" }}
{{- if $layout }}
{{- $layout }}
{{- else }}
{{- "v1" }}
{{- end }}
{{- else }}
{{- $pvcName := ternary (printf "cv-storage-certsandlogs-%s-0" $objectname) (printf "%s-certsandlogs" $objectname) (not (not $statefulset)) }}
{{- $pvc := lookup "v1" "PersistentVolumeClaim" $namespace $pvcName }}
{{- if $pvc }}
{{- "v1" }}
{{- else if eq (include "cv.utils.isMinVersion3" (list . 11 42 105)) "true" }}
{{- "v2" }}
{{- else }}
{{- "v1" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Path helpers. Each returns the v1 path on a legacy layout and the standardized v2 path
otherwise, based on cv.installLayoutVersion. Paths verified against the SP42.110 image registry.
*/}}

{{- define "cv.paths.appdata" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/appdata" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%s/appdata" (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{/*
Certificates mount path. v1 mounts the appdata parent; v2 mounts the certificates subdir directly.
*/}}
{{- define "cv.paths.certMountPath" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "%s/certificates" (include "cv.paths.appdata" .) }}
{{- else }}
{{- include "cv.paths.appdata" . }}
{{- end }}
{{- end }}

{{- define "cv.paths.registry" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/CommVaultRegistry" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- "/etc/CommVaultRegistry" }}
{{- end }}
{{- end }}

{{- define "cv.paths.commvaultDB" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/%sDB" (include "cv.utils.getOemPath" .) (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%sDB" (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{- define "cv.paths.commvaultDR" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/%sDR" (include "cv.utils.getOemPath" .) (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%sDR" (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{- define "cv.paths.sw" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/appdata/SW" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%s/SW" (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{- define "cv.paths.mongodb" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/appdata/MongoDB/Data" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%s/MongoDB/Data" (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{- define "cv.paths.jobResults" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/data/commvaultdata/jobResults" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%s/iDataAgent/jobResults" (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{- define "cv.paths.dm2CacheDir" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/data/commvaultdata/jobResults/DM2CacheDir" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%s/iDataAgent/jobResults/%s/iDataAgent/jobResults/DM2CacheDir" (include "cv.utils.getOemPath" .) (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{- define "cv.paths.indexCache" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/data/commvaultdata/IndexCache" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- printf "/opt/%s/MediaAgent/IndexCache" (include "cv.utils.getOemPath" .) }}
{{- end }}
{{- end }}

{{- define "cv.paths.ddb" }}
{{- if eq (include "cv.installLayoutVersion" . | trim) "v2" }}
{{- printf "/var/opt/%s/Instance001/data/commvaultdata/DDB" (include "cv.utils.getOemPath" .) }}
{{- else }}
{{- "/opt/ddb" }}
{{- end }}
{{- end }}
