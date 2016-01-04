---
layout: post
title: "Deploying Kibana Using Nginx as an SSL Proxy"
date: 2016-01-03 01:16
comments: true
categories: [aws,kibana,automation,terraform,packer,infrastructure]
---
In my last [post](http://www.paulstack.co.uk/blog/2016/01/02/building-an-elasticsearch-cluster-in-aws-with-packer-and-terraform/), I described how I use [Packer](https://packer.io/) and [Terraform](https://terraform.io/) to deploy an [ElasticSearch](https://www.elastic.co/products/elasticsearch) cluster. In order to make the logs stored in ElasticSearch searchable, I use [Kibana](https://www.elastic.co/products/kibana). I follow the previous pattern and deploy Kibana using Packer to build an [AMI](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.htm) and then create the infrastructure using Terraform. The Packer template has already taken into account that I want to use [nginx](https://www.nginx.com/) as a proxy. 

###Building Kibana AMIs with Packer and Ansible

The template looks as follows:

{% raw %}
```json 
{
  "variables": {
    "ami_id": "",
    "private_subnet_id": "",
    "security_group_id": "",
    "packer_build_number": "",
  },
  "description": "Kibana Image",
  "builders": [
    {
      "ami_name": "kibana-{{user `packer_build_number`}}",
      "availability_zone": "eu-west-1a",
      "iam_instance_profile": "app-server",
      "instance_type": "t2.small",
      "region": "eu-west-1",
      "run_tags": {
        "role": "packer"
      },
      "security_group_ids": [
        "{{user `security_group_id`}}"
      ],
      "source_ami": "{{user `ami_id`}}",
      "ssh_timeout": "10m",
      "ssh_username": "ubuntu",
      "subnet_id": "{{user `private_subnet_id`}}",
      "tags": {
        "Name": "kibana-packer-image"
      },
      "type": "amazon-ebs"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "inline": [ "sleep 10" ]
    },
    {
      "type": "shell",
      "script": "install_dependencies.sh",
      "execute_command": "echo '' | {{ .Vars }} sudo -E -S sh '{{ .Path }}'"
    },
    {
      "type": "ansible-local",
      "playbook_file": "kibana.yml",
      "extra_arguments": [
        "--module-path=./modules"
      ],
      "playbook_dir": "../../"
    }
  ]
}
```
{% endraw %} 

The install_dependencies.sh script is as described [previously](http://www.paulstack.co.uk/blog/2016/01/02/building-an-elasticsearch-cluster-in-aws-with-packer-and-terraform/)

The ansible playbook for Kibana looks as follows:  

{% raw %}
```yaml
- hosts: all
  sudo: yes

  pre_tasks:
    - ec2_tags:
    - ec2_facts:

  roles:
    - base
    - kibana
    - reverse_proxied
```
{% endraw %}

The playbook installs a base role for all the base pieces of my system (e.g. Logstash, Sensu-client, prometheus node_exporter) and then proceeds to install ElasticSearch.

The Kibana role looks as follows:

{% raw %}  
```yaml  
- name: Download Kibana
  get_url: url=https://download.elasticsearch.org/kibana/kibana/kibana-{{ kibana_version }}-linux-x64.tar.gz dest=/tmp/kibana-{{ kibana_version }}-linux-x64.tar.gz mode=0440

- name: Untar Kibana
  command: tar xzf /tmp/kibana-{{ kibana_version }}-linux-x64.tar.gz -C /opt creates=/opt/kibana-{{ kibana_version }}-linux-x64.tar.gz

- name: Link to Kibana Directory
  file: src=/opt/kibana-{{ kibana_version }}-linux-x64
        dest=/opt/kibana
        state=link
        force=yes

- name: Link Kibana to ElasticSearch
  lineinfile: >
    dest=/opt/kibana/config/kibana.yml
    regexp="^elasticsearch_url:"
    line='elasticsearch_url: "{{ elasticsearch_url }}"'

- name: Create Kibana Init Script
  copy: src=initd.conf dest=/etc/init.d/kibana mode=755 owner=root

- name: Ensure Kibana is running
  service: name=kibana state=started
```
{% endraw %}

The reverse_proxied ansible role looks as follows:

{% raw %}
```yaml
- name: download private key file
  command: aws s3 cp {{ reverse_proxy_private_key_s3_path }} /etc/ssl/private/{{ reverse_proxy_private_key }}

- name: private key permissions
  file: path=/etc/ssl/private/{{ reverse_proxy_private_key }} mode=600

- name: download certificate file
  command: aws s3 cp {{ reverse_proxy_cert_s3_path }} /etc/ssl/certs/{{ reverse_proxy_cert }}

- name: download DH 2048bit encryption
  command: aws s3 cp {{ reverse_proxy_dh_pem_s3_path }} /etc/ssl/{{ reverse_proxy_dh_pem }}

- name: certificate permissions
  file: path=/etc/ssl/certs/{{ reverse_proxy_cert }} mode=644

- apt: pkg=nginx

- name: remove default nginx site from sites-emabled
  file: path=/etc/nginx/sites-enabled/default state=absent

- template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf mode=644 owner=root group=root

- service: name=nginx state=restarted

- file: path=/var/log/nginx
        mode=0755
        state=directory
```
{% endraw %}

This role downloads a private SSL Key and a Certificate from a [S3 bucket](http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html) that is security controlled through [IAM](http://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html). This allows us to configure nginx to act as a proxy. The nginx proxy template is available to [view](https://gist.github.com/stack72/1d76839c6783bd7eea33).

We can then pass a number of variables to our role for use within ansible:

{% raw %}
```yaml
reverse_proxy_private_key: mydomain.key
reverse_proxy_private_key_s3_path: s3://my-bucket/certs/mydomain/mydomain.key
reverse_proxy_cert: mydomain.crt
reverse_proxy_cert_s3_path: s3://my-bucket/certs/mydomain/mydomain.crt
reverse_proxy_dh_pem_s3_path: s3://my-bucket/certs/dhparams.pem
reverse_proxy_dh_pem: dhparams.pem
proxy_urls:
  - reverse_proxy_url: /
    reverse_proxy_upstream_port: 3000
kibana_version: 4.1.0
elasticsearch_url: http://myes.com:9200
```
{% endraw %}

This allows me to easily change the configuration of nginx to patch security vulnerabilities easily.

###Deploying Kibana with Terraform

The infrastructure of the Kibana cluster is now pretty easy. The Terraform script now looks as follows:

```
resource "aws_security_group" "kibana" {
  name = "kibana-sg"
  description = "Kibana Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = ["${aws_security_group.kibana_elb.id}"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = ["${aws_security_group.kibana_elb.id}"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Kibana Node"
  }
}

resource "aws_security_group" "kibana_elb" {
  name = "kibana-elb-sg"
  description = "Kibana Elastic Load Balancer Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Kibana Load Balancer"
  }
}

resource "aws_elb" "kibana_elb" {
  name = "kibana-elb"
  subnets = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  security_groups = ["${aws_security_group.kibana_elb.id}"]
  cross_zone_load_balancing = true
  connection_draining = true
  internal = true

  listener {
    instance_port      = 443
    instance_protocol  = "tcp"
    lb_port            = 443
    lb_protocol        = "tcp"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "tcp"
    lb_port            = 80
    lb_protocol        = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    target              = "TCP:443"
    timeout             = 5
  }
}

resource "aws_launch_configuration" "kibana_launch_config" {
  image_id = "${var.kibana_ami_id}"
  instance_type = "${var.kibana_instance_type}"
  iam_instance_profile = "app-server"
  key_name = "${aws_key_pair.terraform.key_name}"
  security_groups = ["${aws_security_group.kibana.id}","${aws_security_group.node.id}"]
  enable_monitoring = false

  root_block_device {
    volume_size = "${var.kibana_volume_size}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kibana_autoscale_group" {
  name = "kibana-autoscale-group"
  availability_zones = ["${aws_subnet.primary-private.availability_zone}","${aws_subnet.secondary-private.availability_zone}","${aws_subnet.tertiary-private.availability_zone}"]
  vpc_zone_identifier = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]
  launch_configuration = "${aws_launch_configuration.kibana_launch_config.id}"
  min_size = 2
  max_size = 100
  health_check_type = "EC2"
  load_balancers = ["${aws_elb.kibana_elb.name}"]

  tag {
    key = "Name"
    value = "kibana"
    propagate_at_launch = true
  }

  tag {
    key = "role"
    value = "kibana"
    propagate_at_launch = true
  }

  tag {
    key = "elb_name"
    value = "${aws_elb.kibana_elb.name}"
    propagate_at_launch = true
  }

  tag {
    key = "elb_region"
    value = "${var.aws_region}"
    propagate_at_launch = true
  }
}
```

This allows me to scale my system up or down just by changing the values in my Terraform configuration. When the instances are instantiated, the Kibana instances are added to the ELB and they are then available to serve traffic
