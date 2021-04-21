resource "aws_iam_user" "munya_excel" {
  name = "munya-excel-${var.environment}"
}

resource "aws_iam_access_key" "munya_excel" {
  user = aws_iam_user.munya_excel.name
}

data "aws_iam_policy_document" "excel_s3" {
  statement {
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.excel.id}",
      "arn:aws:s3:::${aws_s3_bucket.excel.id}/*",
    ]
  }
}

resource "aws_iam_user_policy" "munya_excel_s3" {
  name = "munya-excel-${var.environment}"
  user = aws_iam_user.munya_excel.name

  policy = data.aws_iam_policy_document.excel_s3.json
}

locals {
  oidc_provider = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  current_accid = data.aws_caller_identity.current.account_id
}

module "grafana_cloudwatch_iam" {
  source             = "git@github.com:praekeltfoundation/kustomize-monitoring.git//terraform/modules/aws/grafana_cloudwatch?ref=v0.0.11"
  issuer_url         = module.eks.cluster_oidc_issuer_url
  aws_account_id     = local.current_accid
}
