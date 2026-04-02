resource "aws_kms_key" "secrets_kms_key" {
    description = "${var.name_prefix} - application encryption key"
    deletion_window_in_days = 30
    enable_key_rotation = true

    policy = data.aws_iam_policy_document.secrets_key_policy.json
}

resource "aws_kms_alias" "secrets_kms_key" {
    name = "alias/${var.name_prefix}/secrets"
    target_key_id = aws_kms_key.secrets_kms_key.key_id
}

resource "aws_kms_key" "services_kms_key" {
    description = "${var.name_prefix} - Services encryption key"
    deletion_window_in_days = 30
    enable_key_rotation = true

    policy = data.aws_iam_policy_document.services_key_policy.json
}

resource "aws_kms_alias" "services_kms_key" {
    name = "alias/${var.name_prefix}/services"
    target_key_id = aws_kms_key.services_kms_key.key_id
}


resource "aws_kms_key" "cloudwatch" {
    description = "${var.name_prefix} - CloudWatch Logs encryption key"
    deletion_window_in_days = 30
    enable_key_rotation = true

    policy = data.aws_iam_policy_document.cloudwatch_key_policy.json
}

resource "aws_kms_alias" "cloudwatch" {
    name = "alias/${var.name_prefix}/cloudwatch"
    target_key_id = aws_kms_key.cloudwatch.key_id
}