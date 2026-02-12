# Kubernetes Namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = "rateacharacter"
  }
}

# ConfigMap for Application Configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    COGNITO_DOMAIN             = data.terraform_remote_state.infra.outputs.cognito_domain
    COGNITO_DOMAIN_URL         = "https://${data.terraform_remote_state.infra.outputs.cognito_domain}.auth.${data.terraform_remote_state.infra.outputs.aws_region}.amazoncognito.com"
    COGNITO_USER_POOL_CLIENT_ID = data.terraform_remote_state.infra.outputs.cognito_user_pool_client_id
    COGNITO_USER_POOL_ID       = data.terraform_remote_state.infra.outputs.cognito_user_pool_id
    DYNAMODB_SESSIONS_TABLE_NAME = data.terraform_remote_state.infra.outputs.dynamodb_sessions_table_name
    DYNAMODB_USERS_TABLE_NAME   = data.terraform_remote_state.infra.outputs.dynamodb_users_table_name
    SQS_QUEUE_URL              = data.terraform_remote_state.infra.outputs.sqs_queue_url
    EC2_PUBLIC_IP              = data.terraform_remote_state.infra.outputs.ec2_public_ip
    API_PORT                   = "8080"
  }
}

# Secret for sensitive AWS credentials
resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  type = "Opaque"

  data = {
    AWS_ACCESS_KEY = data.terraform_remote_state.infra.outputs.aws_access_key_value
    AWS_SECRET_KEY = data.terraform_remote_state.infra.outputs.aws_secret_key_value
  }
}

# Backend Deployment
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.app.metadata[0].name
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
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.aws_credentials.metadata[0].name
            }
          }
        }
      }
    }
  }
}

# Backend Service
resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.app.metadata[0].name
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
  metadata {
    name      = "portal"
    namespace = kubernetes_namespace.app.metadata[0].name
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
  metadata {
    name      = "portal"
    namespace = kubernetes_namespace.app.metadata[0].name
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
  metadata {
    name      = "portal-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
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
              name = kubernetes_service.portal.metadata[0].name
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
