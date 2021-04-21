provider "aws" {
    version = "2.70.0"
}
module "bootstrap" {
  source = "trussworks/bootstrap/aws"

  region        = "af-south-1"
  account_alias = "munya-qa"
}
