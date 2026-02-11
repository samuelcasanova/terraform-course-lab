# Kubernetes Namespace
resource "kubernetes_namespace" "app" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name = "rateacharacter"
  }
}

# ConfigMap for Application Configuration
resource "kubernetes_config_map" "app_config" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app[0].metadata[0].name
  }

  data = {
    COGNITO_DOMAIN             = aws_cognito_user_pool_domain.main.domain
    COGNITO_DOMAIN_URL         = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
    COGNITO_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
    COGNITO_USER_POOL_ID       = aws_cognito_user_pool.users.id
    DYNAMODB_SESSIONS_TABLE_NAME = aws_dynamodb_table.sessions.name
    DYNAMODB_USERS_TABLE_NAME   = aws_dynamodb_table.users.name
    SQS_QUEUE_URL              = aws_sqs_queue.event_bus.id
    ALB_DNS_NAME               = aws_lb.main.dns_name
    EC2_PUBLIC_IP              = aws_instance.k3s_node.public_ip
    API_PORT                   = "8080"
  }
}

# Secret for sensitive AWS credentials
resource "kubernetes_secret" "aws_credentials" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name      = "aws-credentials"
    namespace = kubernetes_namespace.app[0].metadata[0].name
  }

  type = "Opaque"

  data = {
    AWS_ACCESS_KEY = var.aws_access_key
    AWS_SECRET_KEY = var.aws_secret_key
  }
}

# Backend Deployment
resource "kubernetes_deployment" "backend" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.app[0].metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend"
        }
      }
      spec {
        container {
          name  = "backend"
          image = "samuelcasanovadev/rateacharacter-backend:latest"
          port {
            container_port = 8080
          }
          
          # Use both ConfigMap and Secret for environment variables
          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config[0].metadata[0].name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.aws_credentials[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

# Backend Service
resource "kubernetes_service" "backend" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.app[0].metadata[0].name
  }
  spec {
    selector = {
      app = "backend"
    }
    port {
      port        = 8080
      target_port = 8080
    }
  }
}

# Portal Deployment
resource "kubernetes_deployment" "portal" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name      = "portal"
    namespace = kubernetes_namespace.app[0].metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "portal"
      }
    }
    template {
      metadata {
        labels = {
          app = "portal"
        }
      }
      spec {
        container {
          name  = "portal"
          image = "samuelcasanovadev/rateacharacter-portal:latest"
          port {
            container_port = 3000
          }
          env {
            name  = "PROXY_TARGET"
            value = "http://backend:8080" # Service discovery in K8s
          }
        }
      }
    }
  }
}

# Portal Service
resource "kubernetes_service" "portal" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name      = "portal"
    namespace = kubernetes_namespace.app[0].metadata[0].name
  }
  spec {
    selector = {
      app = "portal"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

# Ingress to expose the portal via Traefik (comes with k3s)
resource "kubernetes_ingress_v1" "portal" {
  count = var.k8s_enabled ? 1 : 0
  metadata {
    name      = "portal-ingress"
    namespace = kubernetes_namespace.app[0].metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }
  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.portal[0].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
