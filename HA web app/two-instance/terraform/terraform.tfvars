project  = "learning"
vpc_cidr = "172.0.0.0/16"

public_subnets = {
  pub-1 = {
    cidr = "172.0.0.0/24"
    az   = "us-west-1a"
  }

  pub-2 = {
    cidr = "172.0.1.0/24"
    az   = "us-west-1c"
  }
}

private_subnets = {
  pri-1 = {
    cidr = "172.0.2.0/24"
    az   = "us-west-1a"
  }

  pri-2 = {
    cidr = "172.0.3.0/24"
    az   = "us-west-1c"
  }
}