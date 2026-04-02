variable "name_prefix" { 
    type = string 
}

variable "aws_region" { 
    type = string 
}

variable "aws_account_id" {
     type = string 
}

variable "private_app_subnets" { 
    type = list(string) 
}

variable "app_sg_id" { 
    type = string 
}

variable "capacity_providers" { 
    type = list(string) 
}

variable "execution_role_arn" { 
    type = string 
}

variable "task_role_arn" { 
    type = string 
}

variable "alb_target_group_arn" { 
    type = string 
}

variable "kms_key_arn" { 
    type = string 
}

variable "log_group_name" { 
    type = string 
}

variable "ecr_api_repo_url" { 
    type = string 
}

variable "ecr_worker_repo_url" { 
    type = string
}

variable "ecr_sched_repo_url" { 
    type = string 
}

variable "db_secret_arn" { 
    type = string 
}

variable "app_secret_arn" { 
    type = string 
}

variable "ecs_task_cpu" { 
    type = number 
}

variable "ecs_task_memory" { 
    type = number 
}

variable "api_desired_count" { 
    type = number 
}

variable "worker_desired_count" { 
    type = number 
}

variable "container_port" { 
    type = number 
}
