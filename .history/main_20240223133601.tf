# EC2 Instance for Computational Seismic Analysis
resource "aws_instance" "seismic_analysis_instance" {
  ami           = "ami-12345678"
  instance_type = "t2.large"
  key_name      = "my-key-pair"

  tags = {
    Name = "Seismic Analysis Instance"
  }
}

# S3 Buckets for Data Storage
resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-seismic-data-bucket" 
  acl    = "private"
  versioning {
    enabled = true
  }
}

# RDS Instance for Database
resource "aws_db_instance" "seismic_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "dbadmin"
  password             = "securepassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  iam_database_authentication_enabled = true

  backup_retention_period = 7
  maintenance_window      = "Mon:03:00-Mon:04:00"
}

# Redshift Cluster for Data Warehousing
resource "aws_redshift_cluster" "seismic_redshift_cluster" {
  cluster_identifier  = "seismic-redshift-cluster"
  database_name       = "seismicdata"
  master_username     = "redshiftadmin"
  master_password     = var.redshift_master_password
  node_type           = "dc2.large"
  cluster_type        = "single-node"
  skip_final_snapshot = true
}

# IAM User for Access Management
resource "aws_iam_user" "seismic_user" {
  name = "seismic_user"
}

resource "aws_iam_user_policy_attachment" "seismic_user_s3_read_only" {
  user       = aws_iam_user.seismic_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Kinesis for Real-Time Data Streaming
resource "aws_kinesis_stream" "seismic_data_stream" {
  name             = "seismic-data-stream"
  shard_count      = 1
  retention_period = 24
}

# AWS Glue for ETL
resource "aws_glue_catalog_database" "seismic_glue_db" {
  name = "seismic-glue-database"
}

resource "aws_iam_role" "glue_service_role" {
  name = "glue_service_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "glue.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_crawler" "seismic_glue_crawler" {
  name          = "seismic-data-crawler"
  database_name = aws_glue_catalog_database.seismic_glue_db.name
  role          = aws_iam_role.glue_service_role.arn

  s3_target {
    path = "s3://your-seismic-data-path"
  }
}

# Amazon EMR for Big Data Processing
resource "aws_emr_cluster" "seismic_emr_cluster" {
  name          = "seismic-emr-cluster"
  release_label = "emr-6.3.0"
  applications  = ["Hadoop", "Hive", "Spark"]
  service_role  = aws_iam_role.emr_service_role.arn

  ec2_attributes {
    subnet_id                         = var.subnet_id
    emr_managed_master_security_group = var.master_sg_id
    emr_managed_slave_security_group  = var.slave_sg_id
    instance_profile                  = aws_iam_instance_profile.emr_instance_profile.arn
  }

  master_instance_group {
    instance_type  = "m4.large"
    instance_count = 1
  }

  core_instance_group {
    instance_type  = "m4.large"
    instance_count = 2
  }
}

# AWS Lake Formation Setup
resource "aws_lakeformation_resource" "seismic_lake_resource" {
  arn = aws_s3_bucket.data_bucket.arn
}

# Amazon SageMaker for Machine Learning
resource "aws_iam_policy" "sagemaker_full_access_policy" {
  name        = "SageMakerFullAccessPolicy"
  description = "Policy granting full access to Amazon SageMaker resources."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "sagemaker:Create*",
        "sagemaker:Delete*",
        "sagemaker:Describe*",
        "sagemaker:Get*",
        "sagemaker:List*",
        "sagemaker:Update*",
        "sagemaker:Search*",
        "sagemaker:AddTags",
        "sagemaker:DeleteTags",
      ],
      Resource = "*",
    }],
  })
}

resource "aws_iam_role" "sagemaker_service_role" {
  name = "SageMakerServiceRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "sagemaker.amazonaws.com" },
      Action    = "sts:AssumeRole",
    }],
  })
}

resource "aws_iam_policy_attachment" "sagemaker_policy_attachment" {
  name       = "SageMakerPolicyAttachment"
  policy_arn = aws_iam_policy.sagemaker_full_access_policy.arn
  roles      = [aws_iam_role.sagemaker_service_role.name]
}

# VPC for Secure Network Setup
resource "aws_vpc" "seismic_vpc" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags = {
    Name = "SeismicVPC"
  }
}

resource "aws_subnet" "seismic_subnet" {
  vpc_id     = aws_vpc.seismic_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "seismic_sg" {
  name        = "seismic_sg"
  description = "Security group for seismic analysis EC2 instances"
  vpc_id      = aws_vpc.seismic_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Amazon CloudWatch for Monitoring
resource "aws_cloudwatch_log_group" "seismic_log_group" {
  name = "/aws/seismic/logs"
  retention_in_days = 30
}

# AWS Lambda for Automation
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole",
    }],
  })
}

resource "aws_iam_policy_attachment" "lambda_exec_policy_attachment" {
  name       = "lambda_exec_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
  roles      = [aws_iam_role.lambda_exec_role.name]
}

resource "aws_lambda_function" "seismic_data_processor" {
  function_name    = "seismicDataProcessor"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("./lamda/function.zip")
  filename         = "./lambda/function.zip"

  memory_size = 128
  timeout     = 30
}

resource "aws_iam_policy" "lambda_custom_policy" {
  name        = "lambda_custom_policy"
  description = "Custom IAM policy for Lambda function"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = ["arn:aws:s3:::your-bucket-name/*"],
      },
      {
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"],
        Resource = ["arn:aws:dynamodb:your-region:your-account-id:table/your-table-name"],
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "lambda_custom_policy_attachment" {
  name       = "lambda_custom_policy_attachment"
  policy_arn = aws_iam_policy.lambda_custom_policy.arn
  roles      = [aws_iam_role.lambda_exec_role.name]
}

# Backup and Disaster Recovery
resource "aws_backup_plan" "seismic_backup_plan" {
  name = "SeismicBackupPlan"

  rule {
    rule_name         = "DailyBackup"
    target_vault_name = aws_backup_vault.seismic_backup_vault.name
    schedule          = "cron(0 12 * * ? *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 90
    }
  }
}

resource "aws_backup_vault" "seismic_backup_vault" {
  name = "SeismicBackupVault"
}
