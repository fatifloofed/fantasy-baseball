resource "aws_secretsmanager_secret" "db" {
    name = "${var.name_prefix}/rds/credentials"
    kms_key_id = var.kms_key_arn

    recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db" {
    secret_id = aws_secretsmanager_secret.db.id

    # Rotate after first deploy
    secret_string = jsonencode({
        username = "dbadmin"
        password = "rotate-me-please"
        engine  = "postgres"
        port    = 5432
    })
    lifecycle {
        ignore_changes = [secret_string]
    }
}

resource "aws_secretsmanager_secret" "app" {
    name = "${var.name_prefix}/app/credentials"
    kms_key_id = var.kms_key_arn

    recovery_window_in_days = 7
}


resource "aws_secretsmanager_secret_version" "app" {
    secret_id = aws_secretsmanager_secret.app.id

    # Rotate after first deploy
    secret_string = jsonencode({
        api_key = "rotate-me-please"
    })
    
    lifecycle {
        ignore_changes = [secret_string]
    }
}