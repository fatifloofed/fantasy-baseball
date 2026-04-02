resource "aws_iam_role" "ecs_execution" {
    name = "${var.name_prefix}-ecs-execution-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
    
    tags = {
        Name = "${var.name_prefix}-ecs-execution-role"
    }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
    role = aws_iam_role.ecs_execution.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
    name = "${var.name_prefix}-ecs-execution-secrets"
    role = aws_iam_role.ecs_execution.id

    policy = data.aws_iam_policy_document.ecs_execution_secrets.json
}

resource "aws_iam_role" "ecs_task" {
  name        = "${var.name_prefix}-ecs-task-role"
  description = "ECS task role assumed by the running container."

  assume_role_policy = data.aws_iam_policy_document.ecs_task_app.json
}