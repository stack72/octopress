---
layout: post
title: "Building an Autodiscovering Apache Zookeeper Cluster in AWS using Packer, Ansible and Terraform"
date: 2016-01-15 15:55
comments: true
categories: [aws,infrastructure,automation,zookeeper,packer,terraform]
---
Following my [pattern](http://www.paulstack.co.uk/blog/2016/01/02/building-an-elasticsearch-cluster-in-aws-with-packer-and-terraform/) of building [AMIs](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) for applications, I create my [Apache Zookeeper](https://zookeeper.apache.org/) cluster with [Packer](https://packer.io/) for my AMI and [Terraform](https://terraform.io/) for the infrastructure. This Zookeeper cluster is auto-discovering of the other nodes that are determined to be in the cluster

###Building Zookeeper AMIs with Packer

The packer template looks as follows:

{% raw %}   
```json
{
  "variables": {
    "ami_id": "",
    "private_subnet_id": "",
    "security_group_id": "",
    "packer_build_number": "",
  },
  "description": "Zookeeper Image",
  "builders": [
    {
      "ami_name": "zookeeper-{{user `packer_build_number`}}",
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
        "Name": "zookeeper-packer-image"
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
      "playbook_file": "zookeeper.yml",
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

The ansible playbook for Zookeeper looks as follows:

{% raw %}
```yaml
- hosts: all
  sudo: yes

  pre_tasks:
    - ec2_tags:
    - ec2_facts:

  roles:
    - base
    - zookeeper
    - exhibitor
```
{% endraw %}

The base playbook installs a base role for all the base pieces of my system (e.g. Logstash, Sensu-client, prometheus node_exporter) and then proceeds to install zookeeper. As a last step, I install [exhibitor](https://github.com/Netflix/exhibitor). Exhibitor is a co-process for monitoring, backup/recovery, cleanup and visualization of zookeeper.

The zookeeper ansible role looks as follows:

{% raw %}   
```yaml   
- name: Download ZooKeeper
  get_url: url=http://www.mirrorservice.org/sites/ftp.apache.org/zookeeper/current/zookeeper-{{ zookeeper_version }}.tar.gz dest=/tmp/zookeeper-{{ zookeeper_version }}.tar.gz mode=0440

- name: Unpack Zookeeper
  command: tar xzf /tmp/zookeeper-{{ zookeeper_version }}.tar.gz -C /opt/ creates=/opt/zookeeper-{{ zookeeper_version }}

- name: Link to Zookeeper Directory
  file: src=/opt/zookeeper-{{ zookeeper_version }}
        dest=/opt/zookeeper
        state=link
        force=yes

- name: Create zookeeper group
  group: name=zookeeper system=true state=present

- name: Create zookeeper user
  user: name=zookeeper groups=zookeeper system=true home=/opt/zookeeper

- name: Create Zookeeper Config Dir
  file: path={{zookeeper_conf_dir}} owner=zookeeper group=zookeeper recurse=yes state=directory mode=0644

- name: Create Zookeeper Transations Dir
  file: path=/opt/zookeeper/transactions owner=zookeeper group=zookeeper recurse=yes state=directory mode=0644

- name: Create Zookeeper Log Dir
  file: path={{zookeeper_log_dir}} owner=zookeeper group=zookeeper recurse=yes state=directory mode=0644

- name: Create Zookeeper DataStore Dir
  file: path={{zookeeper_datastore_dir}} owner=zookeeper group=zookeeper recurse=yes state=directory mode=0644

- name: Setup log4j
  template: dest="{{zookeeper_conf_dir}}/log4j.properties" owner=root group=root mode=644 src=log4j.properties.j2
```
{% endraw %}

The role itself is very simple. The zookeeper cluster is managed by exhibitor so there are very few settings passed to zookeeper at this point. One thing to note though, this requires an installation of the [Java JDK](http://docs.oracle.com/javase/7/docs/webnotes/install/) to work.

The exhibitor playbook looks as follows:

{% raw %}   
```yaml  
- name: Install Maven
  apt: pkg=maven state=latest update_cache=yes

- name: Create Exhibitor Install Dir
  file: path={{ exhibitor_install_dir }} state=directory mode=0644

- name: Create Exhibitor Build Dir
  file: path={{ exhibitor_install_dir }}/{{ exhibitor_version }} state=directory mode=0644

- name: Create Exhibitor POM
  template: src=pom.xml.j2
            dest={{ exhibitor_install_dir }}/{{ exhibitor_version }}/pom.xml

- name: Build Exhibitor jar
  command: '/usr/bin/mvn clean package -f {{ exhibitor_install_dir }}/{{ exhibitor_version }}/pom.xml creates={{ exhibitor_install_dir }}/{{ exhibitor_version }}/target/exhibitor-{{ exhibitor_version }}.jar'

- name: Copy Exhibitor jar
  command: 'cp {{ exhibitor_install_dir }}/{{ exhibitor_version }}/target/exhibitor-{{ exhibitor_version }}.jar {{exhibitor_install_dir}}/exhibitor-standalone-{{ exhibitor_version }}.jar creates={{exhibitor_install_dir}}/exhibitor-standalone-{{ exhibitor_version }}.jar'

- name: Exhibitor Properties Config
  template: src=exhibitor.properties.j2
            dest={{ exhibitor_install_dir }}/exhibitor.properties

- name: exhibitor upstart config
  template: src=upstart.j2 dest=/etc/init/exhibitor.conf mode=644 owner=root

- service: name=exhibitor state=started
```   
{% endraw %}

This role has a lot more configuration to set as it essentially manages zookeeper. The [template files](https://gist.github.com/stack72/e5ccf1bb2bc5da484712) for configuration are all available to download.

The variables for the entire playbook look as follows:

```
zookeeper_hosts: "{{ansible_fqdn}}:2181"
zookeeper_version: 3.4.6
zookeeper_conf_dir: /etc/zookeeper/conf
zookeeper_log_dir: /var/log/zookeeper
zookeeper_datastore_dir: /var/lib/zookeeper
zk_s3_bucket_name: "mys3bucket"
monasca_log_level: WARN
exhibitor_version: 1.5.5
exhibitor_install_dir: /opt/exhibitor
``` 

The main thing to note here is that the exhibitor process starts with the following configuration:

{% raw %}
```bash
exec java -jar {{ exhibitor_install_dir }}/exhibitor-standalone-{{exhibitor_version}}.jar --port 8181 --defaultconfig /opt/exhibitor/exhibitor.properties --configtype s3 --s3config {{ zk_s3_bucket_name }}:{{ ansible_ec2_placement_region }} --s3backup true --hostname {{ ec2_private_ip_address }} > /var/log/exhibitor.log 2>&1
``` 
{% endraw %}

This means that the node will check itself into a configuration file in S3 and that all other zookeepers will read the same configuration file and can form the cluster required. You can read more about Exhibitor shared configuration on their [github wiki](https://github.com/Netflix/exhibitor/wiki/Shared-Configuration).

When I launch the instances now, the zookeeper cluster will be formed

###Deploying Zookeeper Infrastructure with Terraform

The infrastructure of the Zookeeper cluster is pretty simple:

{% raw %}
```
resource "aws_security_group" "zookeeper" {
  name = "digit-zookeeper-sg"
  description = "Zookeeper Security Group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ZooKeeper Node"
  }
}

resource "aws_launch_configuration" "zookeeper_launch_config" {
  image_id = "${var.zookeeper_ami_id}"
  instance_type = "${var.zookeeper_instance_type}"
  iam_instance_profile = "zookeeper-server"
  key_name = "${aws_key_pair.terraform.key_name}"
  security_groups = ["${aws_security_group.zookeeper.id}","${aws_security_group.node.id}"]
  enable_monitoring = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "${var.digit_zookeeper_volume_size}"
  }
}

resource "aws_autoscaling_group" "zookeeper_autoscale_group" {
  name = "zookeeper-autoscale-group"
  availability_zones = ["${aws_subnet.primary-private.availability_zone}","${aws_subnet.secondary-private.availability_zone}","${aws_subnet.tertiary-private.availability_zone}"]
  vpc_zone_identifier = ["${aws_subnet.primary-private.id}","${aws_subnet.secondary-private.id}","${aws_subnet.tertiary-private.id}"]  launch_configuration = "${aws_launch_configuration.zookeeper_launch_config.id}"
  min_size = 0
  max_size = 100
  desired = 3

  tag {
    key = "Name"
    value = "zookeeper"
    propagate_at_launch = true
  }

  tag {
    key = "role"
    value = "zookeeper"
    propagate_at_launch = true
  }
}

```
{% endraw %}

When Terraform is applied here, a 3 node cluster of zookeeper will be created. You can go to [exhibitor](http://mynodeip:8181/exhibitor/v1/ui/index.html) and see the configuration e.g.

![Image](/images/exhibitor-zookeeper-cluster.png)
![Image](/images/exhibitor-zookeeper-cluster-config.png)

