---
title: "Taming Cloud Infrastructure with NixOS, Terraform, and Colmena"
date: 2024-12-17
tags: ["Nix", "terraform", "devops"]
---

Hey there! 👋 I'd like to share a way to provision and manage servers that is fully reproducible, declarative, and powerful enough to deploy a full-stack application,
including a PostgreSQL database, multiple containers, and a reverse proxy.

We'll use these three amazing tools:

- Terraform to provision NixOS servers in the cloud
- The Nix language to write declarative configurations for every aspect of our servers
- Colmena to manage and deploy these configurations across our server fleet

This is not an in-depth tutorial on NixOS – which is quite a rabbit hole! – but rather a bird's eye view of how NixOS enables a fully declarative approach to server management, which I hope will
encourage you to learn more about it.

## 1. What's NixOS and Why Should You Care?

Before we dive in, let's talk about NixOS. NixOS is a Linux distribution that is built on top of Nix, a package manager and build system designed to enable reproducible builds. Nix builds packages from source, and in isolation, following precise instructions expressed in its own functional programming language (which is also named Nix). Nix treats packages and build instructions the way functional programming languages such as OCaml treat pure values and
pure functions: builds are free from side effects, entirely deterministic, and can be reasoned about in isolation.

NixOS extends this concept to an entire operating system, where the configuration of the system is entirely expressed in the Nix language. This means that you can describe your desired system state in a way that is
entirely reproducible and free from side effects, and then apply that configuration to your system.

On a NixOS system, the Nix programming language can be used to configure almost every aspect of the system, including:
- System packages and services
- Network configuration and firewall rules
- User accounts
- File system layout
- Enabled kernel modules
- Systemd services
- Docker containers running on the system

Having a declarative and reproducible configuration for the system also unlocks new abilities, such as:
- Checking out your entire system configuration in a git repository
- Configuring a computer from a remote machine
- Rolling back to any previous system state
- Keeping multiple generations of your system configuration and booting into any of them

In the rest of this post, I'll try to showcase some of these abilities and how they can apply to the deployment of a full-stack web application.

## 2. Setting Up the Foundation with Terraform

First things first - we need some servers. I use Terraform to provision the infrastructure on Hetzner Cloud[^1], though this setup could work with any cloud provider. Let's break down how this works.

### 2.1. Basic Infrastructure Setup

With start by installing the Hetzner provider and configuring it so it knows where to find the Hetzner API token. Of course, this is specific to Hetzner so you'll need to adapt it to your cloud provider.

```hcl
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
```

Like most cloud providers, Hetzner supports private networks. We set one up for secure communication between our servers:

```hcl
resource "hcloud_network" "private_network" {
  name     = "private-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "default_private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}
```

### 2.2. Provisioning Servers

For each service, we create a server with specific requirements. Here's how we provision our preprod environment:

```hcl
resource "hcloud_server" "preprod_server" {
  name        = "preprod"
  server_type = "cx22"
  image       = "debian-12"
  location    = "nbg1"

  network {
    network_id = hcloud_network.private_network.id
    # this will be the ip of the server in the private network
    # the public ip won't be known until the server is provisioned
    ip         = "10.0.1.3"
  }

  ssh_keys = ["default-ssh-key"]
}
```

You'll notice that we use Debian as the base OS for the server. Hetzner cannot deploy NixOS servers out of the box, but it does not mean we cannot use NixOS on them, as we are about to see.

### 2.3. The Magic of NixOS-infect

Now here's where it gets interesting. Instead of manually installing NixOS, we use a clever tool called NixOS-infect. It's essentially a script that converts a running Linux system into NixOS. We've wrapped this in a Terraform module:

```hcl
module "NixOS_install_preprod_server" {
  source      = "./modules/NixOS-install"
  target_host = hcloud_server.preprod_server.ipv4_address
}
```

Behind the scenes, our NixOS-install module does something pretty neat:

```hcl
# this is ./modules/NixOS-install/main.tf
# the module executes a command on the target host, through ssh
# the command is the NixOS-infect script, which will convert the system to NixOS

resource "null_resource" "NixOS_install" {
  connection {
    type    = "ssh"
    user    = var.ssh_user
    host    = var.target_host
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = [
      "curl https://raw.githubusercontent.com/elitak/NixOS-infect/master/NixOS-infect | PROVIDER=hetznercloud Nix_CHANNEL=NixOS-24.11 bash 2>&1 | tee /tmp/infect.log",
    ]
  }
}
```

This module:
1. Connects to the newly created Debian server via SSH
2. Downloads and runs NixOS-infect
3. Converts the system to NixOS while it's running (pretty cool, right?)
4. Reboots into a fresh NixOS installation

The beauty of this approach is that it works on almost any cloud provider - you just need to be able to create a Linux VM and have SSH access. No need for custom NixOS images or complex installation procedures.

There is a caveat though: you should only attempt this on newly-provisioned servers as NixOS-infect carries a risk of corrupting the server and making it unusable. In our case,
since we are using Terraform to provision fresh servers, this should not be an issue.

## 3. Applying our first NixOS configuration

Now that we have a brand new NixOS server, we can test the premise of a fully declarative linux system, by applying our first modification to the system.
If you are already familiar with NixOS, you can skip this section; if not, let's SSH into our server and apply a simple change to the system.

```bash
ssh root@...
```

Now that we are logged in, let's try to print a message using `cowsay`

```bash
[root@preprod:~]# cowsay
The program 'cowsay' is not in your PATH. It is provided by several packages.
You can make it available in an ephemeral shell by typing one of the following:
  Nix-shell -p cowsay
  Nix-shell -p neo-cowsay
```

The `cowsay` program is not installed on the system, but NixOS will suggest a way to use it, in a temporary shell. Nix shells are a powerful way to access packages from Nixpkgs without making any changes to the system,
but that's not quite the point of this post. Instead let's install the `cowsay` package on the system.

In NixOS, by default, the configuration of the system lives in the `/etc/NixOS/configuration.Nix` file. Let's edit this file to install the `cowsay` package.

```bash
sudo nano /etc/NixOS/configuration.Nix
```

You'll notice that the file already contains a few things that were automatically generated when NixOS was installed. We are not going to modify these, but instead add `environment.systemPackages = [ pkgs.cowsay ];`
to the configuration, so the whole file should look like this:

```Nix
{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.Nix
    ./networking.Nix # generated at runtime by NixOS-infect
    
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "preprod";
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObbgbVGRKovUnYzivmY1/X2eBZ9E/+LZIiObWKfufTy'' ];
  system.stateVersion = "23.11";

  # our new configuration
  environment.systemPackages = [ pkgs.cowsay ];
}
```

And once the file is saved, we can apply the changes to the system by running `NixOS-rebuild switch`.

```bash
[root@preprod:~]# NixOS-rebuild switch
```

And after a while, we should be able to run the newly-installed `cowsay` program.

```bash
[root@preprod:~]# cowsay Hello from Nix
 ________________
< Hello from Nix >
 ----------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

Nothing too extraordinary, but the fundamental difference compared to imperative package management (i.e. `apt install cowsay`) is that instead of mutating the system, we are *declaring* what the state
of the system should be using configuration files. These configuration files can be checked into a repository and version-controlled, and used to deploy identically configured systems very easily.

I've barely scratched the surface of what NixOS can do, but let's move on to the next step for now :) 

## 4. Enter Colmena: Your NixOS Fleet Manager

SSH-ing into a server to edit a configuration file using nano is not exactly a scalable solution. Instead, most people will want to store their configuration is a git repository, edit it
using their favorite editor, and then apply the changes to their system using `NixOS-rebuild`, which works perfectly for a single host. However, since this is is a post about server management, I'll
showcase a tool that allows you to manage a fleet of NixOS hosts.

Enter [Colmena](https://github.com/zhaofengli/colmena). Colmena is a tool that allows you to apply a NixOS configuration to a fleet of hosts. It lets you share a common configuration across your fleet, tag hosts
to deploy only a subset of hosts, and more. 

To use Colmena, we need to create a `hive.Nix` file, which will contain a list of hosts and their configurations, among other things.

```Nix
let
  NixOS_24_11 = builtins.fetchTarball {
    name = "NixOS-24.11";
    url = "https://github.com/nixos/nixpkgs/archive/nixos-24.11.tar.gz";
    sha256 = "1cb6dmpfsz4zyk41b6z07nhrf20c8b6ryb103kc6088c2vm63ycv";
  };
in
{
  # Here, we can pin Nixpkgs to a specific version. This is some Nix concept beside the scope of this post,
  # but the tl;dr is that it makes our configuration more reproducible in the future, by specifying the exact version of all packages that we use,
  # kind of like a lockfile.
  meta = {
    Nixpkgs = (import NixOS_24_11) {
      config.allowUnfree = true;
      system = "x86_64-linux";
    };
  };

  # This is where we define the base configuration for all hosts
  defaults = { pkgs, ... }: {
    imports = [ ./modules/base.Nix ];
  };

  # This is where we define first host
  my-host = { name, nodes, ... }: {
    deployment.targetHost = "188.245.210.16";
    imports = [ ./hosts/my-host.Nix ];
  };

  # We can define as many hosts as we want, and they will all be deployed
  # when we run `colmena apply`.
}
```

Every host automatically gets our base configuration, and then we can layer on specific roles.

## 5. Sane Defaults for Every Host

Speaking of base configuration, here's what every server gets automatically (from `base.Nix`):

```Nix
{
  # Enable fail2ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
  };

  # Configure the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  # Install some essential packages
  environment.systemPackages = with pkgs; [
    neovim wget curl htop
  ];
}
```

No more forgetting to install essential tools or configure basic security!

## 6. Deploying a Full-Stack Application

Alright, we have a basic server up and running, now let's get into the fun part: deploying an actual application to it.

### 6.1. PostgreSQL with Automated Backups

Let's start with the database. We will deploy and configure the following:

- Postgresql, as our database engine
- pgBackRest, a backup tool for Postgres, which we will configure to store our backups in S3, and run a full backup of our database daily

We will do so in a [custom module](https://Nix.dev/tutorials/module-system/a-basic-module/), which we can reuse for multiple hosts with different configurations. 
A module is a way to encapsulate a set of options and attributes as to reuse them in multiple contexts. 

This particular Postgre module is rather long, but hopefully, the comment will give you a good idea of what's going on.
And even though writing Nix modules can be tedious, this complexity pays off in the long run, as we can reuse this module for many hosts.

Anyways, here's the module:

```Nix
# ./modules/postgresql.Nix
# A custom Nix module for PostgreSQL that can be used to deploy a PostgreSQL server on a host with continuous backup to S3
{ config, pkgs, lib, ... }:

with lib;
let 
    cfg = config.myModules.postgresql;
in
{

    # Here we define the available options for the module; the public interface of the module if you will.
    # We can then define the values for these options in the configuration of our hosts to deploy the database with the desired configuration
    options.myModules.postgresql = {
        enable = mkEnableOption "Enable PostgreSQL";

        postgresql = {
            port = mkOption {
                type = types.port;
                default = 5432;
            };
            package = mkOption {
                type = types.package;
                default = pkgs.postgresql_17;
                description = "PostgreSQL package to use";
            };
            initialScript = mkOption {
                type = types.path;
                description = "Initial script to run on PostgreSQL server startup";
            };
        };

        pgbackrest = {
            # this particular option is a list of objects, each representing a repository for pgbackrest
            # this makes it possible to backup our database to multiple S3 buckets. We don't have to use more than one, but it's a nice feature to have
            # since we can then backup to different cloud providers and regions
            repositories = mkOption {
                type = types.listOf (types.submodule {
                    options = {
                        repo_index = mkOption {
                            type = types.int;
                            description = "Index of the repository";
                            default = 1;
                        };
                        s3_bucket = mkOption {
                            type = types.str;
                            description = "S3 bucket to use for pgbackrest backups";
                        };
                        s3_backups_path = mkOption {
                            type = types.str;
                            default = "backups";
                            description = "Path in the S3 bucket to use for pgbackrest backups";
                        };
                        s3_region = mkOption {
                            type = types.str;
                            description = "Region of the S3 bucket";
                            default = "eu-west-1";
                        };
                        s3_endpoint = mkOption {
                            type = types.str;
                            description = "Endpoint of the S3 bucket";
                            default = "s3.eu-west-1.amazonaws.com";
                        };
                        s3_access_key = mkOption {
                            type = types.str;
                            description = "Access key for the S3 bucket";
                        };
                        s3_secret_key = mkOption {
                            type = types.str;
                            description = "Secret key for the S3 bucket";
                        };
                    };
                });
                default = [];
                description = "S3 repositories configuration for pgbackrest backups";
            };

            # This option defines how many full backups we want to keep
            retention = {
                full = mkOption {
                    type = types.int;
                    description = "Number of full backups to keep";
                    default = 2;
                };
            };

            # And finally, this option defines the schedule for the backups
            schedule = {
                full = mkOption {
                    type = types.str;
                    description = "Schedule for full backups (systemd calendar format)";
                    default = "weekly";
                };
            };

        };
    };

    # Now that we have our options defined, here is the actual configuration that the module will apply to the host
    # It delegates most of the work to packages and modules available in Nixpkgs and NixOS, but also adds some custom logic.

    # For instance, starting a postgresql database by settings `services.postgresql.enable = true;` is a built-in feature of NixOS, but I have edited the settings
    # of the database to fit my needs.
    config = {
        
        # Start the PostgreSQL service
        services.postgresql = {
            enable = cfg.enable;

            # Use the port option we defined earlier
            port = cfg.postgresql.port;

            # Use the package option we defined earlier (which defaults to PostgreSQL 17)
            package = cfg.postgresql.package;

            # Use the initialScript option we defined earlier, so users of this module can pass a script to run on the database server startup
            initialScript = cfg.postgresql.initialScript;

            # Allow all local connections and password authentication on the network
            authentication = pkgs.lib.mkOverride 10 ''
                # Managed by a Nix module
                #type database  DBuser  auth-method
                local all       all     trust

                # allow password authentication on all interfaces
                host  all       all      all     scram-sha-256
            '';

            # Configure postgres
            # This Nix option lets us declare the content of the postgresql.conf file
            # We can use it to enable WAL archiving (which is required for pgbackrest), tune performance settings, and more
            settings = {
                # Enable WAL archiving
                archive_mode = "on";
                # Here we set the command that will be used to archive the WAL files
                # We use pgbackrest to push the WAL files to the S3 bucket
                # Rather than hardcoding the path to the pgbackrest binary, we can use string interpolation to reference the pgbackrest package from Nixpkgs.
                # Nix will install this package, store it somewhere in /Nix/store, and the correct path to the binary will be reflected in the `postgresql.conf` file
                archive_command = "${pkgs.pgbackrest}/bin/pgbackrest --stanza=main archive-push %p";
                archive_timeout = "300";
        
                # Recommended settings for better performance
                max_wal_size = "1GB";
                min_wal_size = "80MB";
        
                # Connection settings
                listen_addresses = lib.mkForce "*";
                max_connections = "100";
            };
        };

        # Install pgbackrest
        environment.systemPackages = [ pkgs.pgbackrest ];

        # Configure pgBackRest
        # We can use environment.etc to declare the content and the ownership of a file on the host
        # We can use use the full power of the Nix language to generate the content of the file: functions, string interpolation, etc.
        environment.etc."pgbackrest/pgbackrest.conf".owner = "postgres";
        environment.etc."pgbackrest/pgbackrest.conf".text = 
            let
                # This function generates the configuration for a single repository
                # It takes a repository object as an argument and returns a string that will be used to configure the repository in the pgbackrest.conf file
                # Since we have not one but a list of repositories, we need to go through that list, apply the function to each repository, and then concatenate the results into a single string
                # that we can insert into the pgbackrest.conf file
                mkRepoConfig = repo: ''
                    repo${toString repo.repo_index}-type=s3
                    repo${toString repo.repo_index}-s3-bucket=${repo.s3_bucket}
                    repo${toString repo.repo_index}-s3-region=${repo.s3_region}
                    repo${toString repo.repo_index}-path=${repo.s3_backups_path}
                    repo${toString repo.repo_index}-s3-endpoint=${repo.s3_endpoint}
                    repo${toString repo.repo_index}-s3-key=${repo.s3_access_key}
                    repo${toString repo.repo_index}-s3-key-secret=${repo.s3_secret_key}
                    repo${toString repo.repo_index}-s3-uri-style=path
                '';
                # The concatMapStringsSep function from the Nixpkgs library does exactly what we want: it applies the function to each repository, and then concatenates the results into a single string
                # Kind of like `map + join` in javascript, or `foldMap` in haskell
                repos_config = lib.strings.concatMapStringsSep "\n" mkRepoConfig cfg.pgbackrest.repositories;
            in ''
                [global]
                ${repos_config}
                process-max=4
                log-level-console=info
                log-level-file=debug
                    
                [main]
                pg1-path=/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}
                pg1-port=${toString cfg.postgresql.port}
                
                archive-async=y
                archive-push-queue-max=4GB
                retention-full=${toString cfg.pgbackrest.retention.full}
                start-fast=y
                '';

        # This is yet another example of what you can declaratively configure in NixOS: we've seen packages, files, postgresql, and now, systemd units!
        # This particular systemd service will run a full backup of the database. We can launch it manually using `systemctl start pgbackrest-full-backup`
        # or we can associate it with a systemd timer to run the backup on a schedule.
        systemd.services.pgbackrest-full-backup = {
            description = "pgBackRest Full Backup Service";
            after = [ "postgresql.service" ];
            requires = [ "postgresql.service" ];
            path = [ pkgs.pgbackrest ];
            
            serviceConfig = {
                Type = "oneshot";
                User = "postgres";
                Group = "postgres";
            };

            script = ''
                if ! pgbackrest info; then
                    pgbackrest --stanza=main stanza-create
                fi
                pgbackrest --stanza=main --type=full backup
            '';
        };

        # Here we define a systemd timer to run the full backup on a schedule
        systemd.timers.pgbackrest-full-backup = {
            description = "Timer for pgBackRest Full Backup";
            wantedBy = [ "timers.target" ];
            
            timerConfig = {
                # Run the backup on the schedule that was passed in the options of the module
                OnCalendar = cfg.pgbackrest.schedule.full;
                Persistent = true;
            };
        };

        # Finally, we need to create a couple of directories for pgbackrest to work
        systemd.tmpfiles.rules = [
            # Create a directory for pgbackrest logs
            "d /var/log/pgbackrest 0700 postgres postgres -"
            # Create a directory for pgbackrest transient data
            "d /var/spool/pgbackrest 0700 postgres postgres -"
        ];
    };
}

```

That's it for the postgresql module. Congrats on reading through that, I swear this was the largest code snippet in this post!

Even though this module can be intimidating, I find it relatively simple given that it handles all of the following:
- Setting up PostgreSQL with proper configurations
- Configuring pgBackRest for S3 backups
- Creating systemd timers for scheduled backups

With this module, you won't need to run any ad-hoc commands to deploy a database, and you can be sure that the database will be deployed with the desired configuration.
Speaking of which, let's see how to actually use it!

In the `./hosts/my-host.Nix` file, which will be applied by Colmena to our host, we can now import our module and specify the values of all the options we defined in the module.

```Nix
{
  imports = [ ./modules/postgresql.Nix ];

  myModules.postgresql = {
    enable = true;
    postgresql = {
      port = 5432;
      package = pkgs.postgresql_17;
      initialScript = pkgs.writeText "init-db.sql" ''
        CREATE USER application_user WITH PASSWORD 'abcdefg';
        CREATE DATABASE application;
        GRANT ALL PRIVILEGES ON DATABASE application TO application_user;
        ALTER DATABASE application OWNER TO application_user;
        \c application;
        GRANT ALL ON SCHEMA public TO application_user;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO application_user;
      '';
    };
    pgbackrest = {
      repositories = [
        { 
          s3_bucket = "my-bucket"; 
          s3_region = "eu-west-1"; 
          s3_backups_path = "/application-backups"; 
          s3_endpoint = "s3.eu-west-1.amazonaws.com";
          s3_access_key = "MY_ACCESS_KEY";
          s3_secret_key = "MY_SECRET_KEY";
        }
      ];
    };
  };
}
```

This is all we need to deploy a PostgreSQL server with pgBackRest backups to S3, thanks to our reusable module! You'll notice that the initial script option lets you
create a database user, a database, and grant the required privileges to the user, so even this part of the configuration is fully reproducible!

...

But actually, we have a problem here: we have an S3 secret key and a database password, hardcoded in our configuration! Before we can apply this configuration and deploy the rest of our application, we need
to take a short detour to the world of ✨ secrets management ✨.

### 6.2. Secret Management with sops-Nix

You should never commit passwords in your repository. That's where [sops-Nix](https://github.com/Mic92/sops-Nix) comes in. Sops-Nix is an integration layer between [sops](https://github.com/getsops/sops), a tool for encrypting secrets, and NixOS.
Sops lets you edit YAML, JSON and other files, and encrypt them with `age` or `PGP`. Sops will let you encrpyt the files using several public keys, so you can provision
a key pair for every one of your hosts, use sops to edit the files, and safely commit the encrypted files to your repository, knowing that only the hosts with the correct private keys will be able to decrypt them.

This should not feel too unfamiliar if you've used Ansible vaults or similar tools before[^1].

Once you have provisioned a key pair for every one of your hosts (which you can do with the `Nix-shell -p age --command "age-keygen -o /var/lib/sops-Nix/key.txt"` command for instance), you declare the public keys of your
hosts in a `.sops.yaml` configuration file, which tells sops which keys to use to encrypt the secret files, like this

```yaml
# .sops.yaml
creation_rules:
  - path_regex: .*
    key_groups:
      - age:
          # This is the public key of the host
          - 1234567890123456789012345...
```

Then you can use `sops` to create or edit a secret file and put whatever sensitive information you want in it, like this

```bash
# With Nix-shell, you don't even have to install sops to use it!
Nix-shell -p sops --run "sops ./secrets/myHost.yaml"
```

At this point, the `myHost.yaml` file is completely safe to commit to your repository, but it's not used anywhere yet. Let's use `sops-Nix` to bring our encrypted values to our NixOS configuration.

We must start by declaring the available secrets:

```Nix
# ./hosts/myHost.Nix
{
    # Here we declare the available secrets and the location of the encrypted files which contain them
    sops.secrets = {
        backup_key_id.sopsFile = ../secrets/myHost.yaml;
        backup_key_secret.sopsFile = ../secrets/myHost.yaml;
        application_db_password.sopsFile = ../secrets/myHost.yaml;

        # This is a surprise tool that will help us later ;)
        docker_registry_password.sopsFile = ../secrets/myHost.yaml;
    };

    # ... rest of the configuration remains unchanged
}
```

Then we can use the templating feature of sops-Nix to inject our secrets into the init script of our database

```Nix
# ./hosts/myHost.Nix
{
    sops.templates."init-db.sql" = {
        content = ''
            CREATE USER application_user WITH PASSWORD '${config.sops.placeholder.application_db_password}';
            CREATE DATABASE application;
            # ... rest of the script remains unchanged
        '';
        owner = "postgres";
    };
    myModules.postgresql = {
        enable = true;
        postgresql = {
            # sops-Nix will render our template, inject our secrets in the init script, and give us the path to the rendered file,
            # so we can use that path here
            initialScript = config.sops.templates."init-db.sql".path;
        };
        pgbackrest = {
            repositories = [
                { 
                    s3_bucket = "my-bucket"; 
                    s3_region = "eu-west-1"; 
                    s3_backups_path = "/application-backups"; 
                    s3_endpoint = "s3.eu-west-1.amazonaws.com";
                    # Here we can use placeholders to inject our secrets in the configuration, but only
                    # if we update the postgresql module to make use of sops-Nix's templating feature
                    s3_access_key = config.sops.placeholder.backup_key_id;
                    s3_secret_key = config.sops.placeholder.backup_key_secret;
                }
            ];
        };
    };
}
```
We will need to make a small change to the postgresql module to make use of sops-Nix's templating feature. Specifically, we need to replace 

```Nix
{
    environment.etc."pgbackrest/pgbackrest.conf".owner = "postgres";
    environment.etc."pgbackrest/pgbackrest.conf".text =  ...;
}
```

with

```Nix
{
    sops.templates."pgbackrest.conf".content = ...;
    environment.etc."pgbackrest/pgbackrest.conf" = {
        source = config.sops.templates."pgbackrest.conf".path;
        user = "postgres";
    };

}
```

And that's it! We can backup our database to S3, knowing that only we can decrypt the credentials to our precious S3 bucket, and our database password.

Phew! That was a lot of work, I hope I haven't lost too many of you! For those still reading, let's reward ourselves by deploying and testing our database!
Run `colmena apply`, and after a while, you should be able to connect and run `psql` on the host.

```bash
ssh root@...
[root@preprod:~]# psql -h localhost -U application_user -d application
Password for user application_user: 
psql (16.3)
Type "help" for help.

application=> select 1;
 ?column? 
----------
        1
(1 row)
```

Yay! Now let's deploy some containers!

### 6.3. Deploying Containers Declaratively

Need to run some containers? NixOS has a built-in OCI containers module do to exactly that. Let's update our host configuration to deploy a backend container.

```Nix
# ./hosts/myHost.Nix
{
    # This NixOS module can be used to deploy containers. It will create a systemd service for each container, and can configure them to start them automatically on boot.
    # It uses podman as the default container engine, but you can also use docker if you prefer.
    virtualisation.oci-containers.containers.backend = {
        image = "ghcr.io/my-fullstack-app/backend:latest";
        autoStart = true;

        # You can pass extra options to the container engine. Here I'm using the --network=host option to make the container use the host's network stack.
        # Which makes it easy to connect to the database running on the host from the container
        extraOptions = [ "--network=host" ];

        # Remember about the surprise secret we added earlier? Here we can use it to login to a private docker registry, e.g. GitHub Packages.
        login = {
            registry = "ghcr.io";
            username = "jdoe";
            passwordFile = config.sops.secrets.docker_registry_password.path;
        };

        # We can also easily create a .env file, again taking advantage of sops-Nix's templating feature to inject the database password
        environmentFiles = [ config.sops.templates."backend.env".path ];
    };

    # Feel free to add any env variable you need here
    sops.templates."backend.env" = {
        content = ''
            LOG_LEVEL=debug
            DATABASE_URL=postgresql://application_user:${config.sops.placeholder.application_db_password}@localhost:5432/application
        '';
    };

    # ... rest of the configuration remains unchanged
};
```

> But how should I know about this OCI containers module? And how should I know what options are available?

On top the [module's documentation on NixOS's Wiki](https://NixOS.wiki/wiki/NixOS_Containers), which is a good, if not exhaustive, source of information, 
there is a search engine on [NixOS.org](https://search.NixOS.org/options?channel=24.11&from=0&size=50&sort=relevance&type=packages&query=oci-containers) that lets you search for available options in
any of the built-in Nixpkgs modules. And since options are typed, your configration will not build if you try to use an option that doesn't exist, or if you use an option with the wrong type, making it harder
to misuse the available modules.

Once we apply this configuration (with `colmena apply`), we should be able to see the backend container running on the host.

```bash
ssh root@...
[root@preprod:~]# podman ps
CONTAINER ID  IMAGE                                      COMMAND               CREATED        STATUS      PORTS       NAMES
1234567890  ghcr.io/my-fullstack-app/backend:latest  /bin/sh -c /usr/bin/...  10 seconds ago  Running     -
```

We can leverage the OCI containers module once again to deploy a frontend container.

```Nix
# ./hosts/myHost.Nix
{
    virtualisation.oci-containers.containers.frontend = {
        image = "ghcr.io/my-fullstack-app/frontend:latest";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        # ...
    };
}
```

## 7. Time to let the users in

> Someone's knockin' at the door 🎵 <br>
> Somebody's ringin' the bell 🎵 <br>
> Do me a favor 🎵 <br>
> Open the door and let 'em in 🎵

Okay, so we have a bunch of services running on our host, but because our firewall is configured to only allow SSH and HTTP(S) connections, no one can access them at the moment.
We are going to deploy an nginx instance as a reverse proxy to allow our users to access our services. This approach lets us deploy multiple services on the same host, and ony have a single process handling
incoming HTTP requets.

Nginx will take care of routing the requests to the correct service based on the hostname of the request, or its path, or any criteria we see fit.

```Nix
# ./hosts/myHost.Nix
{
    # Deploying nginx is as easy as enabling the built-in module
    services.nginx = {
        enable = true;

        # We can declare virtual hosts, and configure them to proxy requests to the local services
        # Let's suppose that our frontend is listening on port 3000 and our backend is listening on port 3001
        virtualHosts."myapplication.com" = {
            locations."/" = { proxyPass = "http://localhost:3000"; };
        };
        virtualHosts."api.myapplication.com" = {
            locations."/" = { proxyPass = "http://localhost:3001"; };
        };
    };
}
```

This is all we need to deploy a basic HTTP proxy. Of course, HTTP is not an acceptable protocol in 2024, and we should use HTTPS instead. Let's see how:

```Nix
# ./hosts/myHost.Nix
{
    services.nginx = {
        enable = true;
        # This option will make nginx listen on all interfaces, and serve HTTPS traffic on port 443
        defaultListen = [ { addr = "0.0.0.0"; ssl = true; } ];
        virtualHosts."myapplication.com" = {
            # This option will make nginx automatically redirect HTTP requests to HTTPS
            forceSSL = true;
            locations."/" = { proxyPass = "http://localhost:3000"; };

            # These options let us specifiy the path to an SSL certificate and key, which we can provision ourselves and copy on the host 
            # sslCertificate = toString ./ssl/cert.crt;
            # sslCertificateKey = toString ./ssl/cert.key;

            # Or alternatively, the nginx module can use let's encrypt to automatically provision a certificate for us
            enableACME = true;
        };
    };
}
```

All that's left is to `colmena apply` one last time, update our DNS records to point our domain to our host's IP address, and we should be able to 
head over to `https://myapplication.com` and `https://api.myapplication.com` (of course, you'll need to use your own domain name here) and see our application running!

Everything we need to deploy our application lives in these few configuration files. You can destroy the server entirely, you'll have to do is 

- `git clone`
- `terraform apply`
- `colmena apply`
- SSH-ing to the host and use `pgbackrest` to restore a backup, if you want your data back

And you'll have your application running on a fresh server in no time!

## 8. Closing thoughts

I hope this article has given you a good overview of how you can use NixOS to manage your servers and that it has convinced you to dig deeper into NixOS.

I'd like to conclude with a word of warning: in this article, I tried to showcase the key benefits of using NixOS – reproducible and declarative configuration – and omitted
some of Nix's pitfalls on purpose. I should tell you though, that learning Nix is a lot of work. The documentation is not perfect, even if it's constantly improving, and Nix's error messages are notoriously
hard to understand. I've personally found that my previous experience of functional programming has made easier to understand Nix's concepts, but even then, I keep struggling with some of the more complex parts of Nix now and then.

I should also mention that while deploying software that is already available in Nixpkgs is very easy, and using well-maintained NixOS modules, like we did with Postgres and Nginx, is a breeze,
packaging your own software can be quite an undertaking.

So, should you use it anyway? It all comes down to this: Nix is fundamentally changing the software supply chain, and such a radical change is not without its drawbacks. Enthuastic Nix users endure
its steep learning curve and its pain points because they believe in this exciting future for the software supply chain, or, more modestly, 
because they feel like the benefits outweigh the costs. I can't vouch that you'll feel the same, but I encourage you to give it a try!

Happy Nixing! 🚀

[^1]: If you want to learn more about how to use sops-Nix, there is a fantastic video of [Vimjoyer](https://www.youtube.com/watch?v=G5f6GC7SnhU)