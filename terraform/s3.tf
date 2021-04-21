resource "aws_s3_bucket" "excel" {
  bucket = "munya-excel-${var.environment}"
}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  iam_user    = aws_iam_user.munya_excel.name
}

data "aws_iam_policy_document" "excel" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:user/${local.iam_user}"]
    }
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.excel.id}",
      "arn:aws:s3:::${aws_s3_bucket.excel.id}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "excel" {
  bucket = aws_s3_bucket.excel.id

  policy = data.aws_iam_policy_document.excel.json
}
