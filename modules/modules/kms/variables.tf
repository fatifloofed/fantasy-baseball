variable "name_prefix" {
  description = "The prefix for naming resources"
  type        = string
}

variable "aws_account_id" {
    description = "Manage the KMS key policy"
    type = string
}

variable "aws_region" {
    description = "AWS Region"
    type = string
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "secrets_key_policy" {
    statement {
        sid = "EnableIAMUserPermissions"
        effect = "Allow"
        principals {
            type = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        actions = ["kms:*"]
        resources = ["*"]
    }

    statement {
        sid = "RestrictToSecretsManager"
        effect = "Deny"
        principals {
            type = "AWS"
            identifiers = ["*"]
        }
        actions = [
            "kms:Encrypt",
            "kms:GenerateDataKey",
            "kms:Decrypt",
            "kms:CreateGrant"
        ]
        resources = ["*"]
        condition {
            test = "StringNotEquals"
            variable = "kms:ViaService"
            values = ["secretsmanager.${var.aws_region}.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "services_key_policy" {
    statement {
        sid = "EnableIAMUserPermissions"
        effect = "Allow"
        principals {
            type = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        actions = ["kms:*"]
        resources = ["*"]
    }

    statement {
        sid = "AllowAWSServices"
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = [
                "rds.${var.aws_region}.amazonaws.com",
                "s3.${var.aws_region}.amazonaws.com",
                "ecr.${var.aws_region}.amazonaws.com"
            ]
        }
        actions = [
            "kms:DescribeKey",
            "kms:GenerateDataKey",
            "kms:Decrypt",
        ]
        resources = ["*"]
        condition {
            test = "StringEquals"
            variable = "aws:SourceAccount"
            values = [data.aws_caller_identity.current.account_id]
        }

        condition {
            test = "ArnLike"
            variable = "aws:SourceArn"
            values = [
                "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:${var.name_prefix}-*",
                "arn:aws:s3:::${var.name_prefix}-*",
                "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.name_prefix}/*"
            ]
        }
    }

    statement {
        sid = "AllowRDSGrants"
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = [
                "rds.${var.aws_region}.amazonaws.com"
            ]
        }
        actions = [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
        ]
        resources = ["*"]
        condition {
            test = "StringEquals"
            variable = "aws:SourceAccount"
            values = [data.aws_caller_identity.current.account_id]
        }
    }
}

data "aws_iam_policy_document" "cloudwatch_key_policy" {
    statement {
        sid = "AllowAdministrationKey"
        effect = "Allow"
        principals {
            type = "AWS"
            identifiers = [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            ]
        }
        actions = [ "kms:*" ]
        resources = ["*"]
    }

    statement {
        sid = "AllowCloudWatchLogs"
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = [
                "logs.${var.aws_region}.amazonaws.com"
            ]
        }
        actions = [
            "kms:GenerateDataKey*",
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:ReEncrypt*"
        ]
        resources = ["*"]
        condition {
            test = "ArnLike"
            variable = "kms:EncryptionContext:aws:logs:arn"
            values = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
        }
    }
}