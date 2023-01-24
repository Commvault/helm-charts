<link rel = "icon" href = 
"https://documentation.commvault.com/static/homepage/img/favicon.ico" 
        type = "image/x-icon">
        
<a href="https://commvault.github.io/helm-charts/">
    <img src="https://documentation.commvault.com/static/homepage/img/cmv-logo-full.png" alt="Commvault logo" title="Commvault" align="right" height="50" />
</a>

# Commvault helm-charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add commvault https://commvault.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  

You can then run below command to see the charts.

    helm search repo commvault

Docker hub repository for Commvault - [Repository](https://hub.docker.com/u/commvault)

The First chart to be installed is the Config Chart which holds the config map for all the commvault component chart installs. This needs to be installed always prior to a new chart install.

### Install using \--set

To install the config chart:

    helm upgrade --install config commvault/config --set csOrGatewayHostName=cs.commvault.svc.cluster.local --set secret.user=installuser --set secret.password=password --set global.namespace=commvault --set namespace.create=true
    
To install the commserve chart:

    helm upgrade --install commserve commvault/commserve --set clientName=cs --set global.namespace=commvault --set global.image.tag={tagvalue}
    
To install the webserver chart:

    helm upgrade --install webserver commvault/webserver --set clientName=ws --set global.namespace=commvault --set global.image.tag={tagvalue}
    
To install the commandcenter chart:

    helm upgrade --install commandcenter commvault/commandcenter --set clientName=cc --set webserverName=ws --set global.namespace=commvault --set global.image.tag={tagvalue}

To install the mediaagent chart:

    helm upgrade --install mediaagent commvault/mediaagent --set clientName=ma --set global.namespace=commvault --set global.image.tag={tagvalue}

To install the networkgateway chart:

    helm upgrade --install networkgateway commvault/networkgateway --set clientName=nwg --set global.namespace=commvault --set global.image.tag={tagvalue}
    
To install the accessnode chart:

    helm upgrade --install accessnode commvault/accessnode --set clientName=accessnode --set global.namespace=commvault --set global.image.tag={tagvalue}
    
### Install using values file

Values for different charts are present. ([Here](https://github.com/Commvault/helm-charts/tree/main/valuefiles)). This has detailed explanation for every required and optional fields. There is a common global file for all charts and a local value file for every chart. Values can also be supplied using --set command line parameter.

To install the config chart:

    helm upgrade --install cvconfig commvault/config -f configvalues.yaml -f global.yaml
    
To install the commserve chart:

    helm upgrade --install commserve commvault/commserve -f csvalues.yaml -f global.yaml
    
To install the webserver chart:

    helm upgrade --install webserver commvault/webserver -f webservervalues.yaml -f global.yaml
    
To install the commandcenter chart:

    helm upgrade --install commandcenter commvault/commandcenter -f commandcentervalues.yaml -f global.yaml

To install the mediaagent chart:

    helm upgrade --install mediaagent commvault/mediaagent -f mediaagentvalues.yaml -f global.yaml

To install the networkgateway chart:

    helm upgrade --install networkgateway commvault/networkgateway -f networkgatewayvalues.yaml -f global.yaml
    
To install the accessnode chart:

    helm upgrade --install accessnode commvault/accessnode -f accessnodevalues.yaml -f global.yaml

To uninstall the chart:

    helm delete <chart-name>
