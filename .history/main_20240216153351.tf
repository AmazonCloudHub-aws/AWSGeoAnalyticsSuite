# EC2 Instance for Computational Seismic Analysis
resource "aws_instance" "seismic_analysis_instance" {
  ami           = "ami-12345678"
  instance_type = "t2.large"
  key_name      = "my-key-pair"

  # Additional EC2 configurations like security groups, tags, etc.
  tags = {
    Name = "Seismic Analysis Instance"
  }
}


# S3 Buckets for Data Storage
resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-seismic-data-bucket" # Ensure this is globally unique
  acl    = "private"
  versioning {
    enabled = true
  }

  # Additional S3 configurations like lifecycle rules, logging, etc.
}


# RDS Instance for Database
# Create an IAM role for RDS
resource "aws_iam_role" "rds_iam_role" {
  name = "rds_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "rds_policy_attachment" {
  name       = "rds_policy_attachment" # Add a name for the attachment
  policy_arn = aws_iam_policy.rds_policy.arn
  roles      = [aws_iam_role.rds_iam_role.name]
}

# Create an IAM policy for RDS
resource "aws_iam_policy" "rds_policy" {
  name        = "RDSAccessPolicy"
  description = "IAM policy for RDS access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:CreateDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:DeleteDBSnapshot",
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM role to the RDS instance
resource "aws_db_instance" "seismic_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "dbadmin"
  password             = "securepassword" # Ensure this is securely managed
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

  # Enable IAM database authentication
  iam_database_authentication_enabled = true

  # Additional RDS configurations like backup, maintenance window, etc.
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

  # Additional configurations like shard-level metrics
  shard_level_metrics = ["IncomingBytes", "OutgoingBytes"]
}


# AWS Glue for ETL
resource "aws_glue_catalog_database" "seismic_glue_db" {
  name = "seismic-glue-database"
  # Further configurations like description, location_uri, etc.
}

# Assuming aws_iam_role.glue_service_role is already defined
# IAM Role for AWS Glue
resource "aws_iam_role" "glue_service_role" {
  name = "glue_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Attach the necessary policies for AWS Glue
}

resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}



resource "aws_glue_crawler" "seismic_glue_crawler" {
  name          = "seismic-data-crawler"
  database_name = aws_glue_catalog_database.seismic_glue_db.name
  role          = aws_iam_role.glue_service_role.arn # Ensure this role has necessary permissions

  # Specify the target for the Glue Crawler, which in this case is "s3_target"
  s3_target {
    path = "s3://your-seismic-data-path" # Replace with the actual S3 path where your data is located
  }

  # Additional configurations like schedule, classifiers, etc.
  # Example: Defining a schedule
  # schedule = "cron(0 12 * * ? *)"
}




# Amazon EMR for Big Data Processing

resource "aws_iam_role" "emr_service_role" {
  name = "emr_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "emr_service_policy" {
  role       = aws_iam_role.emr_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}


resource "aws_iam_instance_profile" "emr_instance_profile" {
  name = "emr_instance_profile"
  role = aws_iam_role.emr_ec2_role.name
}

resource "aws_iam_role" "emr_ec2_role" {
  name = "emr_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  # Attach policies as necessary
}

resource "aws_emr_cluster" "seismic_emr_cluster" {
  name          = "seismic-emr-cluster"
  release_label = "emr-6.3.0"                 # Choose appropriate EMR release
  applications  = ["Hadoop", "Hive", "Spark"] # Adjust applications as needed
  service_role  = aws_iam_role.emr_service_role.arn

  ec2_attributes {
    subnet_id                         = var.subnet_id    # Define this variable or hard-code your subnet ID
    emr_managed_master_security_group = var.master_sg_id # Security group for master node
    emr_managed_slave_security_group  = var.slave_sg_id  # Security group for slave nodes
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
  # Additional configurations might include resource role ARNs or other permissions
}


# Amazon SageMaker for Machine Learning
# Create an IAM policy for Amazon SageMaker
resource "aws_iam_policy" "sagemaker_full_access_policy" {
  name        = "SageMakerFullAccessPolicy"
  description = "Policy granting full access to Amazon SageMaker resources."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
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
      },
    ],
  })
}

# Create an IAM role for Amazon SageMaker
resource "aws_iam_role" "sagemaker_service_role" {
  name = "SageMakerServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sagemaker.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

# Attach the SageMaker policy to the SageMaker role
resource "aws_iam_policy_attachment" "sagemaker_policy_attachment" {
  name       = "SageMakerPolicyAttachment"
  policy_arn = aws_iam_policy.sagemaker_full_access_policy.arn
  roles      = [aws_iam_role.sagemaker_service_role.name]
}

# VPC for Secure Network Setup
resource "aws_vpc" "seismic_vpc" {
  cidr_block = "10.0.0.0/16"
  # Additional configurations like enabling DNS support, DNS hostname, tags, etc.
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "SeismicVPC"
  }
}

resource "aws_subnet" "seismic_subnet" {
  vpc_id     = aws_vpc.seismic_vpc.id
  cidr_block = "10.0.1.0/24"
  # Further configurations like availability zone, map public IP on launch, etc.
  availability_zone = "us-west-2a"
}


# Security Group for EC2 Instances
resource "aws_security_group" "seismic_sg" {
  name        = "seismic_sg"
  description = "Security group for seismic analysis EC2 instances"
  vpc_id      = aws_vpc.seismic_vpc.id

  # Define security group rules as needed
  # Example: Allowing inbound SSH traffic
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
  # Additional configurations like retention policy, KMS key id for encryption, etc.
  retention_in_days = 30
}


# AWS Lambda for Automation
# Declare the IAM Role for AWS Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  # Define the trust relationship policy for Lambda
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the AWS managed policy for Lambda execution
resource "aws_iam_policy_attachment" "lambda_exec_policy_attachment" {
  name       = "lambda_exec_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
  roles      = [aws_iam_role.lambda_exec_role.name]
}

# Declare the AWS Lambda function
resource "aws_lambda_function" "seismic_data_processor" {
  function_name    = "seismicDataProcessor"
  role             = aws_iam_role.lambda_exec_role.arn # Ensure this role has necessary permissions
  handler          = "index.handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("./lamda/function.zip")
  filename         = "./lambda/function.zip"

  # Additional configurations like environment variables, memory size, timeout, etc.
  memory_size = 128
  timeout     = 30
}

# Optional: Declare an IAM Policy for more granular permissions if needed
resource "aws_iam_policy" "lambda_custom_policy" {
  name        = "lambda_custom_policy"
  description = "Custom IAM policy for Lambda function"

  # Define the policy document
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ],
        Resource = [
          "arn:aws:s3:::your-bucket-name/*", # Replace with your S3 bucket ARN
        ],
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
        ],
        Resource = [
          "arn:aws:dynamodb:your-region:your-account-id:table/your-table-name", # Replace with your DynamoDB table ARN
        ],
      },
      # Add more permissions as needed
    ],
  })
}

# Attach the custom IAM policy to the Lambda role
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
  # Additional configurations like tags, KMS key id for encryption, etc.
}
