locals {
  name_prefix = "cliffords3"
}

resource "aws_s3_bucket" "static_bucket" {
 bucket = "${local.name_prefix}.sctp-sandbox.com"
 force_destroy = true
 tags = {
    Name        = "Clifford bucket"
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_public_access_block" "enable_public_access" {
    bucket = aws_s3_bucket.static_bucket.id
    /* block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false  */
}

resource "aws_s3_bucket_policy" "allow_public_access" {
    bucket = aws_s3_bucket.static_bucket.id
    policy = <<EOT
    {
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "PublicReadGetObject",
			"Principal": "*",
			"Effect": "Allow",
			"Action": [
				"s3:GetObject"
			],
			"Resource": ["arn:aws:s3:::cliffords3.sctp-sandbox.com/*"]
		}
	]
    }
EOT
}

/* data "aws_iam_policy_document" "allow_access" {
    
  statement {
    principals {
      type        = "AWS"
      identifiers = ["123456789012"]
    }

    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.static_bucket.arn,
      "${aws_s3_bucket.static_bucket.arn}/*",
    ]
  }
} */



resource "aws_s3_bucket_website_configuration" "website" {
    bucket = aws_s3_bucket.static_bucket.id
    index_document {
      suffix = "index.html"
    }
}


data "aws_route53_zone" "sctp_zone" {
 name = "sctp-sandbox.com"
}


resource "aws_route53_record" "www" {
 zone_id = data.aws_route53_zone.sctp_zone.zone_id
 name = "${local.name_prefix}" # Bucket prefix before sctp-sandbox.com
 type = "A"


 alias {
   name = aws_s3_bucket_website_configuration.website.website_domain
   zone_id = aws_s3_bucket.static_bucket.hosted_zone_id
   evaluate_target_health = true
 }
}
