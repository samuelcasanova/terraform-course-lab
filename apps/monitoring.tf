resource "kubernetes_namespace" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}

resource "kubernetes_service_account" "cloudwatch_agent" {
  metadata {
    name      = "cloudwatch-agent"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "cloudwatch_agent" {
  metadata {
    name = "cloudwatch-agent-role"
  }

  rule {
    api_groups = [""]
    resources  = ["events", "namespaces", "nodes", "pods", "pods/logs", "endpoints", "services", "configmaps", "secrets"]
    verbs      = ["list", "watch", "get", "create", "update"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["list", "watch", "get"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["replicasets", "deployments", "daemonsets", "statefulsets"]
    verbs      = ["list", "watch", "get"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["list", "watch", "get"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/proxy", "nodes/stats", "nodes/metrics"]
    verbs      = ["list", "watch", "get"]
  }
  
  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "cloudwatch_agent" {
  metadata {
    name = "cloudwatch-agent-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cloudwatch_agent.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cloudwatch_agent.metadata[0].name
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  }
}

resource "kubernetes_config_map" "cwagentconfig" {
  metadata {
    name      = "cwagentconfig"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  }

  data = {
    "cwagentconfig.json" = jsonencode({
      agent = {
        region = "eu-west-3"
      }
      logs = {
        metrics_collected = {
          kubernetes = {
            cluster_name = "terraform-aws-lab-k3s"
            metrics_collection_interval = 60
          }
        }
        logs_collected = {
          files = {
            collect_list = [
              {
                file_path       = "/rootfs/var/log/syslog"
                log_group_name  = "/aws/ec2/terraform-aws-lab/k3s"
                log_stream_name = "{instance_id}/syslog"
              },
              {
                file_path       = "/rootfs/var/log/cloud-init-output.log"
                log_group_name  = "/aws/ec2/terraform-aws-lab/k3s"
                log_stream_name = "{instance_id}/cloud-init"
              },
              {
                # Collect all pod logs from the rateacharacter namespace
                file_path       = "/var/log/pods/rateacharacter_*/*/*.log"
                log_group_name  = "/aws/ec2/terraform-aws-lab/k3s"
                log_stream_name = "{instance_id}/pods"
              }
            ]
          }
        }
        force_flush_interval = 5
      }
    })
  }
}

resource "kubernetes_daemonset" "cloudwatch_agent" {
  metadata {
    name      = "cloudwatch-agent"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        name = "cloudwatch-agent"
      }
    }

    template {
      metadata {
        labels = {
          name = "cloudwatch-agent"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cloudwatch_agent.metadata[0].name
        host_network         = true
        dns_policy           = "ClusterFirstWithHostNet"

        container {
          name  = "cloudwatch-agent"
          image = "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest"
          
          env {
            name = "HOST_IP"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }
          env {
            name = "HOST_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "K8S_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "CI_VERSION"
            value = "k8s/1.3.16"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "200Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "200Mi"
            }
          }

          volume_mount {
            name       = "cwagentconfig"
            mount_path = "/etc/cwagentconfig"
          }
          
          volume_mount {
            name       = "rootfs"
            mount_path = "/rootfs"
            read_only  = true
          }
          volume_mount {
            name       = "dockersock"
            mount_path = "/var/run/docker.sock"
            read_only  = true
          }
          volume_mount {
            name       = "varlibdocker"
            mount_path = "/var/lib/docker"
            read_only  = true
          }
          volume_mount {
            name       = "containerdsock"
            mount_path = "/run/containerd/containerd.sock"
            read_only  = true
          }
          volume_mount {
            name       = "sys"
            mount_path = "/sys"
            read_only  = true
          }
          volume_mount {
            name       = "devdisk"
            mount_path = "/dev/disk"
            read_only  = true
          }
          volume_mount {
            name       = "varlogpods"
            mount_path = "/var/log/pods"
            read_only  = true
          }
          volume_mount {
            name       = "varlogcontainers"
            mount_path = "/var/log/containers"
            read_only  = true
          }
        }

        volume {
          name = "cwagentconfig"
          config_map {
            name = kubernetes_config_map.cwagentconfig.metadata[0].name
          }
        }
        volume {
          name = "rootfs"
          host_path {
            path = "/"
          }
        }
        volume {
          name = "dockersock"
          host_path {
            path = "/var/run/docker.sock"
          }
        }
        volume {
          name = "varlibdocker"
          host_path {
            path = "/var/lib/docker"
          }
        }
        volume {
           name = "containerdsock"
           host_path {
             path = "/run/k3s/containerd/containerd.sock"
           }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
        volume {
          name = "devdisk"
          host_path {
            path = "/dev/disk"
          }
        }
        volume {
          name = "varlogpods"
          host_path {
            path = "/var/log/pods"
          }
        }
        volume {
          name = "varlogcontainers"
          host_path {
            path = "/var/log/containers"
          }
        }

        termination_grace_period_seconds = 60
      }
    }
  }
}
