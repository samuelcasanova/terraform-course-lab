# Random string for bucket uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for application assets
resource "aws_s3_bucket" "assets" {
  bucket = "${var.project_name}-assets-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-assets"
  }
}

# S3 Bucket for ALB logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project_name}-alb-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-alb-logs"
  }
}

# Ownership controls - Enforced means ACLs are disabled. 
# Reverting to Preferred for logs to avoid potential issues with services expecting ACLs.
resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "alb_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.alb_logs]
  bucket     = aws_s3_bucket.alb_logs.id
  acl        = "private"
}

resource "aws_s3_bucket_ownership_controls" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = false # ALB logs may need some ACL visibility during test
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

# Bucket policy to allow ALB to write logs
# Using both ELB Account ID and Log Delivery service principal
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission for ELB Service Account (eu-west-3: 054676820928)
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::054676820928:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        # Permission for Log Delivery Service
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

# S3 Bucket ACL - only for assets as we keep it preferred
resource "aws_s3_bucket_acl" "assets" {
  depends_on = [aws_s3_bucket_ownership_controls.assets]
  bucket = aws_s3_bucket.assets.id
  acl    = "private"
}
