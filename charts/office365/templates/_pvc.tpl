{{/*
_pvc.tpl is the same for all commvault components. Any change in this file should be copied to the _pvc.tpl in all the components.
*/}}


{{/*
A template for creating a PersistentVolumeClaim for kind: Deployment
*/}}
{{- define "cv.deployment.pvc.tpl" }}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $size := index . 2 }}
{{- $storageClass := index . 3 }}
{{- $pv := index . 4 }}
---
# PVC for {{$name}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "cv.metadataname" $root }}-{{ $name }}
  namespace: {{ include "cv.namespace" $root }}
spec:
  accessModes:
    - ReadWriteOnce
  {{- if $pv }}
  {{- /* Empty string must be explicitly set otherwise default StorageClass will be set */}}
  storageClassName: ""
  volume: {{ $pv }}
  {{- /* Leave this if condition alone. otherwise it can cause problem on restart if storageClassName is blank */}}
  {{- else if $storageClass }}
  storageClassName: {{ $storageClass }} 
  {{- end}}
  resources:
    requests:
      storage: {{ $size }}
{{- end }}

{{/*
A template for creating a PersistentVolumeClaim for kind: Statefulset
*/}}
{{- define "cv.statefulset.pvc.tpl" }}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $size := index . 2 }}
{{- $storageClass := index . 3 }}
  - metadata:
      name: cv-storage-{{ $name }}
    spec:
{{- /*
 leave this if condition alone. otherwise it can cause problem on restart if storageclassname is blank
*/}}
      {{- if $storageClass }}
      storageClassName: {{ $storageClass }}
      {{- end}}
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: {{ $size }}
{{- end }}


{{/*
For creating pvc either storage class (for dynamic provisioning) or pv name can be used.
Storage class can also be blank to use default storage class for dynamic provisioning
storageClass:
  logs: logs

or

storageClass:
  logs_pv: existinglogvol

*/}}
{{- define "cv.deployment.pvc" }}
{{- $root := index . 0 }}
{{- $type := index . 1 }}
{{- $type_size := print $type "_size" }}
{{- $type_pv := print $type "_pv" }}
{{- $defaultsize := index . 2 }}
{{- $name := $type }}
{{- if eq (len .) 4 }}
{{- $name = index . 3 }}
{{- end }}
{{- $storageClass := or (get ($root.Values.storageClass) $type) (get (($root.Values.global).storageClass) $type) "" }}
{{- if ne $storageClass "emptyDir" }}
{{- $size := or (get ($root.Values.storageClass) $type_size) (get (($root.Values.global).storageClass) $type_size) $defaultsize }}
{{- $pv := or (get ($root.Values.storageClass) $type_pv) (get (($root.Values.global).storageClass) $type_pv) "" }}
{{ include "cv.deployment.pvc.tpl" (list $root $name $size $storageClass $pv ) }}
{{- end }}
{{- end }}

{{- define "cv.deployment.additionalVolumes" }}
{{- $objectname := include "cv.metadataname" . }}
{{- $volumes := (fromYaml (include "cv.util.mergelist" (list .Values.volumes ((.Values).global).volumes "volumes"))).volumes }}
{{- range $v := $volumes }}
      - name: cv-storage-{{ $v.name }}
        persistentVolumeClaim:
           claimName: {{ $objectname }}-{{ $v.name }}
{{- end }}
{{- end }}

{{- define "cv.deployment.additionalPvc" }}
{{- $volumes := (fromYaml (include "cv.util.mergelist" (list .Values.volumes ((.Values).global).volumes "volumes"))).volumes }}
{{- $root := . }}
{{- range $v := $volumes }}
{{ include "cv.deployment.pvc.tpl" (list $root $v.name $v.size $v.storageClass $v.volume ) }}
{{- end }}
{{- end }}


{{- define "cv.statefulset.pvctemplate" }}
{{- $root := index . 0 }}
{{- $type := index . 1 }}
{{- $type_size := print $type "_size" }}
{{- $defaultsize := index . 2 }}
{{- $name := $type }}
{{- if eq (len .) 4 }}
{{- $name = index . 3 }}
{{- end }}
{{- $storageClass := or (get ($root.Values.storageClass) $type) (get (($root.Values.global).storageClass) $type) "" }}
{{- $size := or (get ($root.Values.storageClass) $type_size) (get (($root.Values.global).storageClass) $type_size) $defaultsize }}
  - metadata:
      name: cv-storage-{{ $name }}
    spec:
{{- /*
 leave this if condition alone. otherwise it can cause problem on restart if storageclassname is blank
*/}}
      {{- if $storageClass }}
      storageClassName: {{ $storageClass }}
      {{- end}}
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: {{ $size }}
{{- end }}

{{- define "cv.statefulset.additionalPvcTemplates" }}
{{- $root := . }}
{{- $volumes := (fromYaml (include "cv.util.mergelist" (list .Values.volumes ((.Values).global).volumes "volumes"))).volumes }}
{{- range $v := $volumes }}
{{ include "cv.statefulset.pvc.tpl" (list $root $v.name $v.size $v.storageClass ) }}
{{- end }}
{{- end }}


{{- define "cv.additionalVolumeMounts" }}
{{- $volumes := (fromYaml (include "cv.util.mergelist" (list .Values.volumes ((.Values).global).volumes "volumes"))).volumes }}
{{- range $v := $volumes }}
        - name: cv-storage-{{ $v.name }}
          mountPath: {{ $v.mountPath }}
          subPath: {{ $v.subPath }}
{{- end }}
{{- end }}

{{- define "cv.commonVolumeMounts" }}
        - name: cv-storage-certsandlogs
          mountPath: "C:\\Program Files\\Commvault\\ContentStore\\Log Files"
{{- end }}


{{- define "cv.deployment.volumes" }}
{{- $root := index . 0 }}
{{- $type := index . 1 }}
{{- $defaultsize := index . 2 }}
{{- $objectname := include "cv.metadataname" $root }}
{{- $type_size := print $type "_size" }}
{{- $storageClass := or (get ($root.Values.storageClass) $type) (get (($root.Values.global).storageClass) $type) "" }}
{{- $size := or (get ($root.Values.storageClass) $type_size) (get (($root.Values.global).storageClass) $type_size) $defaultsize }}
{{- if eq $storageClass "emptyDir" }}
      - name: cv-storage-{{$type}}
      {{- if $size }}
        emptyDir:
          sizeLimit: {{$size}}
      {{- else }}
        emptyDir: {}
      {{- end }}
{{- else }}
      - name: cv-storage-{{$type}}
        persistentVolumeClaim:
           claimName: {{ $objectname }}-{{$type}}
{{- end }}
{{- end }}
