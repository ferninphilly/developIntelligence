#!/usr/bin/env bash
#setting IP address and hostname
IP="127.0.0.1"
HOST=`ubuntu-xenial`
sed -i "/$IP/ s/.*/$IP\tlocalhost\t$HOST/g" /etc/hosts

#apt-get preamble
echo "apt-get preamble"
sudo apt-get update
sudo apt-get upgrade

# install curl
echo "installing curl"
sudo apt-get -y install curl unzip

# install openjdk-8
echo "installing openjdk-8-jdk because 8"
sudo apt-get purge openjdk*
sudo apt-get -y install openjdk-8-jdk

# install ES
echo "installing ES repo (which has weak SHA btw) and updating installation"
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
sudo apt-get update && sudo apt-get install elasticsearch
sudo update-rc.d elasticsearch defaults 95 10

# either of the next two lines is needed to be able to access "localhost:9200" from the host os
echo "setting up bind to all IPs in the elasticsearch.yml"
sudo echo "network.bind_host: 0" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "network.host: 0.0.0.0" >> /etc/elasticsearch/elasticsearch.yml

# enable cors (to be able to use Sense)
echo "enabling CORS for Sense installation in the elasticsearch.yml"
sudo echo "http.cors.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "http.cors.allow-origin: /https?:\/\/localhost(:[0-9]+)?/" >> /etc/elasticsearch/elasticsearch.yml

# enable dynamic scripting
echo "enabling dynamic scripting in elasticsearch.yml"
sudo echo "script.inline: on" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "script.indexed: on" >> /etc/elasticsearch/elasticsearch.yml

sudo systemctl restart elasticsearch
echo "installing local ES plugins called license and marvel agent"
sudo /usr/share/elasticsearch/bin/plugin install -b --verbose license
sudo /usr/share/elasticsearch/bin/plugin install -b --verbose marvel-agent

#Kibana setup
echo "Kibana repo additions plus kibana service setup"
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/kibana/4.6/debian stable main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update && sudo apt-get install kibana
#https://download.elastic.co/kibana/kibana/kibana-4.6.1-amd64.deb
sudo echo "elasticsearch.url: "http://localhost:9200"" >> /opt/kibana/config/kibana.yml
sudo update-rc.d kibana defaults 95 10
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service
sudo systemctl kibana restart
#install and setup of sense and marvel
echo "installing sense and marvel via kibana plugins"
sudo /opt/kibana/bin/kibana plugin --install elastic/sense
sudo /opt/kibana/bin/kibana plugin --install elasticsearch/marvel/latest
#this was was an odd one.. fix permissions for various reasons.
echo "executing chown on .babelcache.json because kibana has never run before and thus persmission ftw!"
sudo chown kibana:root /opt/kibana/optimize/.babelcache.json
#install head
echo "installing the head plugin directly into ES.  5.0 is going to break this btw"
sudo /usr/share/elasticsearch/bin/plugin install mobz/elasticsearch-head
# restart everything just to make sure
echo "restarting first ES and then Kibana"
sudo systemctl restart elasticsearch
sudo systemctl restart kibana

#pausing for a second because of weird startup issues
echo "pausing for 10 seconds so hold on"
sleep 10
echo "pausing done. resuming script"
#  Data Import for potential labs
echo "attempting to post data to ES.  Not sure why this wouldn't work"
curl -XPOST 'localhost:9200/books/es/1' -d '{"title":"Elasticsearch Server", "published": 2013}'
curl -XPOST 'localhost:9200/books/es/2' -d '{"title":"Elasticsearch Server Second Edition", "published": 2014}'
curl -XPOST 'localhost:9200/books/es/3' -d '{"title":"Mastering Elasticsearch", "published": 2013}'
curl -XPOST 'localhost:9200/books/es/4' -d '{"title":"Mastering Elasticsearch Second Edition", "published": 2015}'
curl -XPOST 'localhost:9200/books/solr/1' -d '{"title":"Apache Solr 4 Cookbook", "published": 2012}'
curl -XPOST 'localhost:9200/books/solr/2' -d '{"title":"Solr Cookbook Third Edition", "published": 2015}'
#import accounts data
echo "downloading files from github repo mmajere/IntrotoES2016"
git clone git://github.com/mmajere/IntroToES2016.git
echo "bulk import of accounts.json which is /bank data for labs"
curl -XPOST 'http://localhost:9200/bank/account/_bulk?pretty' --data-binary "@IntroToES2016/datajson/accounts.json"
echo "bulk import of thebard.json which is /shakespeare data for ES labs"
curl -XPOST 'http://localhost:9200/bank/account/_bulk?pretty' --data-binary "@IntroToES2016/datajson/thebard.json"

