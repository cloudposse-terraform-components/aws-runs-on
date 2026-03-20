terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
<<<<<<< Updated upstream
      version = ">= 4.9.0, < 6.0.0"
=======
      version = ">= 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
>>>>>>> Stashed changes
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 2.0.0, < 3.0.0"
    }
  }
}
