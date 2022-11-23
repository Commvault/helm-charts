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
    
Values for different charts are present. ([Here](https://github.com/Commvault/helm-charts/tree/main/valuefiles)). This has detailed explanation for every required and optional fields. There is a common global file for all charts and a local value file for every chart. Values can also be supplied using --set command line parameter.

Docker hub repository for Commvault - [Repository](https://hub.docker.com/u/commvault)

The First chart to be installed is the Config Chart which holds the config map for all the commvault component chart installs. This needs to be installed always prior to a new chart install.

To install the config chart:

    helm install cvconfig commvault/config -f configvalues.yaml -f global.yaml
    
To install the commserve chart:

    helm install commserve commvault/commserve -f csvalues.yaml -f global.yaml
    
To install the webserver chart:

    helm install webserver commvault/webserver -f webservervalues.yaml -f global.yaml
    
To install the commandcenter chart:

    helm install commandcenter commvault/commandcenter -f commandcentervalues.yaml -f global.yaml

To install the mediaagent chart:

    helm install mediaagent commvault/mediaagent -f mediaagentvalues.yaml -f global.yaml

To install the networkgateway chart:

    helm install networkgateway commvault/networkgateway -f networkgatewayvalues.yaml -f global.yaml
    
To install the accessnode chart:

    helm install accessnode commvault/accessnode -f accessnodevalues.yaml -f global.yaml

To uninstall the chart:

    helm delete <chart-name>
